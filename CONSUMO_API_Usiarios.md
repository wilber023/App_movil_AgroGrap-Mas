# Guía de Consumo — Microservicio de Usuarios y Autenticación (AgroGraph-MAS)

Esta guía documenta cómo cualquier cliente (la app Flutter, un panel de administración web, Postman, etc.) debe consumir el microservicio de Usuarios. Cubre los tres tipos de perfil (`agricultor`, `aprendiz_agricola`, `admin`), todos los endpoints, el formato exacto de cada request/response y el manejo del token de autenticación (access + refresh).

> **Base URL (desarrollo local):** `http://localhost:8000`
> **Base URL (producción / EC2):** `http://http://174.129.218.190` (o detrás de tu reverse proxy/HTTPS si lo configuras)
> **Prefijo de la API:** `/api/v1`
> **Documentación interactiva autogenerada:** `http://<host>:8000/docs` (Swagger UI) y `http://<host>:8000/redoc`

---

## 1. Conceptos clave antes de integrar

### 1.1 Los tres tipos de usuario

| Rol | Quién lo usa | Cómo se crea |
| :--- | :--- | :--- |
| `agricultor` | Usuario final, flujo completo de la app | Registro público: `POST /auth/register/agricultor` |
| `aprendiz_agricola` | Usuario final, funcionalidad "Próximamente" en el cliente | Registro público: `POST /auth/register/aprendiz` |
| `admin` | Equipo interno de AgroGraph | **No tiene registro público.** Existe un admin "semilla" creado automáticamente al desplegar el servicio (vía variables de entorno). Ese admin puede crear nuevos admins desde `POST /auth/register/admin` (requiere estar autenticado como admin). |

El rol **no se envía como campo libre en el body de registro**: cada rol público tiene su propia ruta. Esto evita que cualquiera pueda autoasignarse `admin` enviando `"role": "admin"` en el JSON. El rol queda almacenado en el usuario y se incluye en el JWT y en cada respuesta (`role`).

### 1.2 Formato de los datos: snake_case

Todas las respuestas que devuelven datos de usuario usan **snake_case**, igual que lo espera `UserModel.fromJson()` en el cliente Flutter:

```json
{
  "id": "uuid-v4",
  "full_name": "Wilber Hernandez",
  "username": "wil_hdz",
  "email": "wil@example.com",
  "phone": "+52 123 456 7890",
  "avatar_url": null,
  "access_token": "eyJhbGci...",
  "refresh_token": "dGhpcyBp...",
  "is_local_only": false,
  "created_at": "2026-06-20T03:51:09.010Z",
  "role": "agricultor"
}
```

El cuerpo de la **respuesta es la raíz del JSON** (no hay envoltura `{"data": {...}}`), tal como espera el `AuthRemoteDataSource` actual del cliente.

### 1.3 Fechas

Todas las fechas (`created_at`) se devuelven en **ISO 8601 UTC**, compatibles con `DateTime.tryParse()` de Dart.

---

## 2. El sistema de Tokens (Access + Refresh)

Este servicio usa **dos tokens JWT** con una estrategia de **rotación + blacklist en Redis**, pensada para ser segura sin que el cliente tenga que hacer nada distinto a lo que ya hace hoy.

### 2.1 ¿Qué es cada token?

| Token | Vida útil (configurable en `.env`) | Para qué sirve |
| :--- | :--- | :--- |
| `access_token` | 15 minutos | Se envía en **cada request** a un endpoint protegido, en el header `Authorization`. |
| `refresh_token` | 7 días | Se usa **solo** para pedir un nuevo `access_token` (y un nuevo `refresh_token`) cuando el access expira. |

### 2.2 Cómo enviar el `access_token` en cada request protegido

Todo endpoint protegido (marcado como tal más abajo) exige el header estándar **Bearer**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Ejemplo con `curl`:

```bash
curl -X GET "http://localhost:8000/api/v1/users/me" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

Ejemplo con Dio (Flutter), igual que ya lo maneja el cliente:

```dart
final response = await dio.get(
  '/api/v1/users/me',
  options: Options(
    headers: {'Authorization': 'Bearer $accessToken'},
  ),
);
```

### 2.3 Qué pasa cuando el `access_token` expira (401)

Cuando el `access_token` expira, cualquier endpoint protegido responderá:

```http
HTTP/1.1 401 Unauthorized
```
```json
{ "detail": "Token inválido o expirado." }
```

El cliente debe interceptar este 401 y automáticamente:

1. Llamar a `POST /api/v1/auth/refresh` enviando el `refresh_token` guardado.
2. Si la llamada es exitosa, recibirá un **nuevo par** `access_token` + `refresh_token` (ver rotación abajo). Debe **reemplazar ambos** en su almacenamiento local (Hive).
3. Reintentar la petición original con el nuevo `access_token`.
4. Si el `refresh_token` también es inválido o expiró (401 en `/auth/refresh`), debe cerrar sesión localmente y redirigir al login.

Este patrón es el mismo "interceptor" que ya usan la mayoría de apps con Dio (`dio_interceptor` o similar), no requiere cambios en la arquitectura `Either<Failure, UserEntity>` actual del cliente.

### 2.4 Rotación del Refresh Token (importante)

Cada vez que se usa un `refresh_token` en `/auth/refresh`, el servidor:

1. Verifica que ese refresh token siga siendo válido (existe en Redis, no fue usado antes).
2. Lo **invalida inmediatamente** (rotación).
3. Genera y devuelve un **nuevo** `access_token` y un **nuevo** `refresh_token`.

**Consecuencia práctica para el cliente:** después de llamar a `/auth/refresh`, el cliente **debe sobrescribir** tanto el `access_token` como el `refresh_token` guardados. Si intenta reutilizar un `refresh_token` ya usado, el servidor lo rechazará con 401 (esto protege contra robo de tokens: si alguien roba un refresh token viejo y lo reutiliza después de que el dueño legítimo ya rotó, será rechazado).

### 2.5 Logout: invalidación real del token

A diferencia de un JWT "tonto" que sigue siendo válido hasta que expira por sí solo, este servicio **invalida activamente** los tokens en logout usando una blacklist en Redis:

- El `access_token` enviado se agrega a una blacklist hasta su expiración natural (máx. 15 min restantes).
- El `refresh_token` enviado se elimina de Redis (deja de poder usarse para renovar sesión).

Por eso, en logout se recomienda enviar **ambos tokens** en el body (ver sección 3.4), no solo el access token vía header.

### 2.6 Resumen visual del flujo

```
1. LOGIN/REGISTER  →  recibe access_token (15 min) + refresh_token (7 días)
2. Cada request protegido → Authorization: Bearer <access_token>
3. access_token expira (401) → POST /auth/refresh con el refresh_token
4. Recibe NUEVO access_token + NUEVO refresh_token → reemplaza ambos
5. LOGOUT → envía access_token y refresh_token → servidor los invalida
```

---

## 3. Endpoints de Autenticación (`/api/v1/auth`)

### 3.1 Registro — Agricultor (público)

Crea un usuario con rol `agricultor`.

- **Método:** `POST`
- **Path:** `/api/v1/auth/register/agricultor`
- **Autenticación:** No requerida.

**Request body:**

```json
{
  "fullName": "Wilber Hernandez",
  "username": "wil_hdz",
  "password": "mypassword123",
  "email": "wil@example.com",
  "phone": "+52 123 456 7890"
}
```

| Campo | Tipo | Obligatorio | Validación |
| :--- | :--- | :--- | :--- |
| `fullName` | string | Sí | Mínimo 2 caracteres |
| `username` | string | Sí | Mínimo 3 caracteres, solo `a-zA-Z0-9_` |
| `password` | string | Sí | Mínimo 6 caracteres |
| `email` | string | No | Formato de email válido si se envía |
| `phone` | string | No | — |

**Respuesta exitosa (`201 Created`):**

```json
{
  "id": "9f2c1a3e-2b4d-4e8b-9f1a-2c3d4e5f6a7b",
  "full_name": "Wilber Hernandez",
  "username": "wil_hdz",
  "email": "wil@example.com",
  "phone": "+52 123 456 7890",
  "avatar_url": null,
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "is_local_only": false,
  "created_at": "2026-06-20T07:10:00.000Z",
  "role": "agricultor"
}
```

**Errores posibles:**

| Código | Causa |
| :--- | :--- |
| `400` | `username` o `email` ya están en uso, o falló alguna validación |
| `422` | Body mal formado o campos faltantes/invalidos según el esquema |

---

### 3.2 Registro — Aprendiz Agrícola (público)

Idéntico al anterior, pero asigna el rol `aprendiz_agricola`.

- **Método:** `POST`
- **Path:** `/api/v1/auth/register/aprendiz`
- **Autenticación:** No requerida.
- **Request body:** mismo formato que 3.1.
- **Respuesta:** mismo formato que 3.1, con `"role": "aprendiz_agricola"`.

---

### 3.3 Login

Válido para **cualquiera de los tres roles** (`agricultor`, `aprendiz_agricola`, `admin`). El backend identifica el rol automáticamente según el usuario.

- **Método:** `POST`
- **Path:** `/api/v1/auth/login`
- **Autenticación:** No requerida.

**Request body:**

```json
{
  "username": "wil_hdz",
  "password": "mypassword123"
}
```

**Respuesta exitosa (`200 OK`):** mismo shape que el registro (sección 3.1), con el `role` real del usuario.

**Errores posibles:**

| Código | Causa |
| :--- | :--- |
| `401` | Usuario o contraseña incorrectos, o usuario deshabilitado |
| `422` | Body inválido |

---

### 3.4 Refrescar sesión

Renueva el `access_token` usando el `refresh_token`. Implementa rotación (ver sección 2.4): el refresh token usado se invalida y se entrega uno nuevo.

- **Método:** `POST`
- **Path:** `/api/v1/auth/refresh`
- **Autenticación:** No requiere header `Authorization`; el `refresh_token` va en el body.

**Request body:**

```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Respuesta exitosa (`200 OK`):** mismo shape que login, con `access_token` y `refresh_token` **nuevos**.

**Errores posibles:**

| Código | Causa |
| :--- | :--- |
| `401` | Refresh token inválido, expirado, ya usado/rotado, o usuario inactivo |
| `422` | Body inválido |

---

### 3.5 Logout

Invalida la sesión activa (access token vía blacklist, refresh token eliminándolo de Redis).

- **Método:** `POST`
- **Path:** `/api/v1/auth/logout`
- **Autenticación:** No exige el header `Authorization` (los tokens a invalidar viajan en el body), pero se recomienda enviar ambos tokens para una invalidación completa.

**Request body:**

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

> Ambos campos son opcionales individualmente, pero se recomienda enviar siempre los dos. Si solo se envía uno, solo ese se invalida.

**Respuesta exitosa (`200 OK`):**

```json
{ "message": "Sesión cerrada correctamente." }
```

---

### 3.6 Registro de Admin (protegido — solo admins)

Permite que un administrador **ya autenticado** cree otro administrador. No existe registro público de admins.

- **Método:** `POST`
- **Path:** `/api/v1/auth/register/admin`
- **Autenticación:** **Requerida.** Header `Authorization: Bearer <access_token>` de un usuario con `role = admin`.

**Request body:** mismo formato que 3.1 (`fullName`, `username`, `password`, `email`, `phone`).

**Respuesta exitosa (`201 Created`):** mismo shape que el registro normal, con `"role": "admin"`.

**Errores posibles:**

| Código | Causa |
| :--- | :--- |
| `401` | No se envió token o el token es inválido/expirado |
| `403` | El usuario autenticado no tiene rol `admin` |
| `400` | `username`/`email` ya en uso |

---

## 4. Endpoints de Usuario (`/api/v1/users`)

### 4.1 Obtener mi perfil

- **Método:** `GET`
- **Path:** `/api/v1/users/me`
- **Autenticación:** Requerida (cualquier rol).

**Respuesta exitosa (`200 OK`):**

```json
{
  "id": "9f2c1a3e-2b4d-4e8b-9f1a-2c3d4e5f6a7b",
  "full_name": "Wilber Hernandez",
  "username": "wil_hdz",
  "email": "wil@example.com",
  "phone": "+52 123 456 7890",
  "avatar_url": null,
  "access_token": null,
  "refresh_token": null,
  "is_local_only": false,
  "created_at": "2026-06-20T07:10:00.000Z",
  "role": "agricultor"
}
```

> Nota: este endpoint **no** devuelve tokens (`access_token`/`refresh_token` vienen en `null`), ya que el cliente los obtiene solo en login/register/refresh. Es solo consulta de datos de perfil.

---

### 4.2 Actualizar mi perfil

- **Método:** `PUT`
- **Path:** `/api/v1/users/me`
- **Autenticación:** Requerida (cualquier rol).

**Request body (todos los campos opcionales, solo se actualiza lo enviado):**

```json
{
  "fullName": "Wilber Hernandez Garcia",
  "email": "nuevo_correo@example.com",
  "phone": "+52 987 654 3210",
  "avatarUrl": "https://cdn.agrograph.com/avatars/abc123.jpg"
}
```

**Respuesta exitosa (`200 OK`):** mismo shape que 4.1, con los datos actualizados.

**Errores posibles:**

| Código | Causa |
| :--- | :--- |
| `400` | El nuevo `email` ya está en uso por otro usuario |
| `401` | Token inválido/expirado |

---

### 4.3 Listar usuarios (solo Admin)

- **Método:** `GET`
- **Path:** `/api/v1/users`
- **Autenticación:** Requerida, rol `admin`.
- **Query params opcionales:**
  - `role`: filtra por `agricultor`, `aprendiz_agricola` o `admin`.
  - `skip` (default `0`): paginación, registros a saltar.
  - `limit` (default `50`, máx `200`): cantidad de resultados.

**Ejemplo:**
```
GET /api/v1/users?role=agricultor&skip=0&limit=20
```

**Respuesta exitosa (`200 OK`):** arreglo de objetos con el mismo shape de 4.1 (sin tokens).

---

### 4.4 Detalle de un usuario por ID (solo Admin)

- **Método:** `GET`
- **Path:** `/api/v1/users/{user_id}`
- **Autenticación:** Requerida, rol `admin`.

**Respuesta exitosa (`200 OK`):** un objeto con el shape de 4.1.
**Errores:** `404` si el usuario no existe.

---

### 4.5 Desactivar usuario (solo Admin)

Deshabilita la cuenta (no podrá volver a iniciar sesión hasta ser reactivada).

- **Método:** `PATCH`
- **Path:** `/api/v1/users/{user_id}/deactivate`
- **Autenticación:** Requerida, rol `admin`.
- **Respuesta exitosa (`200 OK`):** usuario actualizado.

### 4.6 Reactivar usuario (solo Admin)

- **Método:** `PATCH`
- **Path:** `/api/v1/users/{user_id}/activate`
- **Autenticación:** Requerida, rol `admin`.
- **Respuesta exitosa (`200 OK`):** usuario actualizado.

---

## 5. Tabla resumen de endpoints

| Método | Path | Rol requerido | Descripción |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/auth/register/agricultor` | Público | Registro de agricultor |
| `POST` | `/api/v1/auth/register/aprendiz` | Público | Registro de aprendiz agrícola |
| `POST` | `/api/v1/auth/register/admin` | Admin | Crear nuevo admin |
| `POST` | `/api/v1/auth/login` | Público | Inicio de sesión (los 3 roles) |
| `POST` | `/api/v1/auth/refresh` | Público* | Renovar tokens (*requiere refresh token válido en el body) |
| `POST` | `/api/v1/auth/logout` | Público* | Cerrar sesión (*requiere tokens válidos en el body) |
| `GET` | `/api/v1/users/me` | Autenticado | Ver mi perfil |
| `PUT` | `/api/v1/users/me` | Autenticado | Actualizar mi perfil |
| `GET` | `/api/v1/users` | Admin | Listar usuarios |
| `GET` | `/api/v1/users/{user_id}` | Admin | Detalle de usuario |
| `PATCH` | `/api/v1/users/{user_id}/deactivate` | Admin | Desactivar usuario |
| `PATCH` | `/api/v1/users/{user_id}/activate` | Admin | Reactivar usuario |
| `GET` | `/health` | Público | Healthcheck del servicio |

---

## 6. Códigos de error generales

| Código HTTP | Significado en este servicio |
| :--- | :--- |
| `200` / `201` | Éxito |
| `204` | Éxito sin contenido (no usado actualmente, se usa 200 con mensaje) |
| `400` | Error de negocio (ej. username/email duplicado) |
| `401` | No autenticado / token inválido, expirado, revocado o reutilizado |
| `403` | Autenticado pero sin permisos para el recurso (rol incorrecto) |
| `404` | Recurso no encontrado (ej. usuario por ID) |
| `422` | Error de validación del body/query (formato incorrecto) |

Todas las respuestas de error siguen el formato estándar de FastAPI:

```json
{ "detail": "Mensaje descriptivo del error." }
```

---

## 7. Variables de entorno relevantes para quien consume el servicio

Aunque la configuración completa vive en el backend, estos valores **afectan directamente el comportamiento que el cliente debe anticipar**:

| Variable | Afecta a... |
| :--- | :--- |
| `ACCESS_TOKEN_EXPIRE_MINUTES` (default 15) | Cada cuánto el cliente recibirá 401 y deberá refrescar |
| `REFRESH_TOKEN_EXPIRE_DAYS` (default 7) | Cada cuánto el usuario deberá volver a loguearse desde cero |

---

## 8. Ejemplo de flujo completo (curl)

```bash
# 1. Registro
curl -X POST http://localhost:8000/api/v1/auth/register/agricultor \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Wilber Hernandez",
    "username": "wil_hdz",
    "password": "mypassword123",
    "email": "wil@example.com"
  }'

# 2. Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "wil_hdz", "password": "mypassword123"}'

# 3. Consultar mi perfil (usar el access_token recibido en el paso 2)
curl -X GET http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer <ACCESS_TOKEN>"

# 4. Refrescar sesión cuando el access_token expire
curl -X POST http://localhost:8000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "<REFRESH_TOKEN>"}'

# 5. Logout
curl -X POST http://localhost:8000/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d '{"accessToken": "<ACCESS_TOKEN>", "refreshToken": "<REFRESH_TOKEN>"}'
```

---

## 9. Notas para el equipo de Admin (panel interno)

- El primer admin **no se registra manualmente**: se crea automáticamente al desplegar el contenedor por primera vez, usando las variables `ADMIN_SEED_USERNAME`, `ADMIN_SEED_PASSWORD`, `ADMIN_SEED_FULL_NAME` y `ADMIN_SEED_EMAIL` del `.env`.
- **Cambia la contraseña del admin semilla después del primer despliegue** (no hay endpoint de "cambiar mi contraseña" en esta primera versión — se puede agregar en una siguiente iteración si lo necesitas).
- Cualquier admin autenticado puede crear más admins vía `POST /api/v1/auth/register/admin`.
- El panel de administración puede usar `GET /api/v1/users?role=agricultor` y `GET /api/v1/users?role=aprendiz_agricola` para construir vistas separadas por tipo de usuario.

---

## 10. Fuera del alcance de este microservicio

Igual que en la especificación original del cliente Flutter, este servicio **solo** maneja usuarios y autenticación. No incluye:

- Gestión de Parcelas y Terrenos.
- Diagnóstico IA o historial de enfermedades.
- Suscripciones / Pagos.
- Agendas de Tratamiento o "Rutas del Cultivo".

Esos dominios deben implementarse como microservicios independientes que **consuman** este servicio (por ejemplo, validando el `access_token` recibido) para identificar al usuario autenticado y su rol.
