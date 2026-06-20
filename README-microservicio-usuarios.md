# Especificación Técnica: Microservicio de Usuarios (AgroGraph-MAS)

Este documento define el contrato de integración para el microservicio de Usuarios y Autenticación. Está basado **estrictamente** en la implementación actual del cliente móvil (Flutter), garantizando que el backend se adapte a los casos de uso, DTOs y modelos ya definidos sin requerir refactorización en la capa de datos del frontend.

---

## 1. Contexto del Dominio (Tipos de Perfil)

El cliente maneja un modelo sellado (`ProfileType`) para determinar el flujo post-autenticación. Aunque la selección de perfil ocurre en la interfaz, los tipos exactos serializados son:

*   `'agricultor'` (Navega al Dashboard principal - `MainShell`)
*   `'aprendiz_agricola'` (Muestra estado `AuthFeatureNotReady` / "Próximamente")

**Nota de Integración:** Actualmente, la capa de dominio en Flutter (ver `RegisterParams` y `LoginParams`) gestiona este rol localmente y no lo incluye en el payload HTTP hacia `AuthRemoteDataSource`. Si el backend requiere asignar o validar roles, será necesario actualizar los DTOs en Flutter en un sprint futuro. Por ahora, el backend no debe requerir obligatoriamente este campo en el body.

---

## 2. Modelo de Datos de Usuario (`UserEntity` / `UserModel`)

El modelo que el cliente espera recibir en cada respuesta de autenticación o perfil. 

| Campo | Tipo Dart | Equivalente JSON | Reglas del Frontend |
| :--- | :--- | :--- | :--- |
| `id` | `String` | `string` (UUID) | **Requerido.** UUID v4. Nunca un entero. |
| `fullName` | `String` | `string` | **Requerido.** Nombre y apellido concatenados. |
| `username` | `String` | `string` | **Requerido.** Único, usado para login. |
| `email` | `String?` | `string` o `null` | Opcional (Flujo offline-first lo permite nulo). |
| `phone` | `String?` | `string` o `null` | Opcional. |
| `avatarUrl` | `String?` | `string` o `null` | Opcional. URL al recurso de imagen. |
| `accessToken` | `String?` | `string` o `null` | El token JWT. Requerido tras login/registro exitoso. |
| `refreshToken` | `String?` | `string` o `null` | Token para renovar sesión. |
| `isLocalOnly`| `bool` | `boolean` | Control local del frontend (defaults to `false`). |
| `createdAt` | `DateTime?` | `string` (ISO 8601) | Opcional. Formato UTC exacto (ej. `2026-06-05T03:51:09.010Z`). |

---

## 3. Validaciones de Registro (`ValidateRegisterFormUseCase`)

El backend debe replicar exactamente estas reglas de negocio aplicadas en el frontend para evitar discrepancias:

*   **`firstName` y `lastName`:** Mínimo 2 caracteres. No pueden ser vacíos. *(En el request al backend, estos viajan concatenados en el campo `fullName`)*.
*   **`username`:** Mínimo 3 caracteres. Expresión regular obligatoria: `^[a-zA-Z0-9_]+$` (Solo letras, números y guion bajo).
*   **`password`:** Mínimo 6 caracteres.
*   **`email` / `phone`:** Totalmente opcionales.

---

## 4. Endpoints Necesarios

Basado en la interfaz `AuthRemoteDataSource` definida en el cliente Flutter.

### 4.1. Iniciar Sesión (Login)
*   **Método:** `POST`
*   **Path sugerido:** `/api/v1/auth/login`
*   **Request Body (DTO de entrada):**
    ```json
    {
      "username": "wil_hdz",
      "password": "mypassword123"
    }
    ```
*   **Respuesta Esperada (`UserModel` con Tokens):**
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
      "created_at": "2026-06-05T03:51:09.010Z"
    }
    ```
*   **Manejo de Errores (Frontend usa `Either<Failure, UserEntity>`):**
    El cliente intercepta fallos de `Dio` y los traduce a `ServerFailure`. El backend debe devolver un código HTTP 401 (Unauthorized) o 400 (Bad Request) con un mensaje descriptivo si falla.

### 4.2. Registro de Usuario
*   **Método:** `POST`
*   **Path sugerido:** `/api/v1/auth/register`
*   **Request Body (`RegisterParams`):**
    ```json
    {
      "fullName": "Wilber Hernandez",
      "username": "wil_hdz",
      "password": "mypassword123",
      "email": "wil@example.com",     // Opcional, puede no enviarse
      "phone": "+52 123 456 7890"     // Opcional, puede no enviarse
    }
    ```
    *(Nota: Asegurar el parseo de `fullName` a camelCase o mapearlo correctamente, ya que el UseCase pasa `fullName: params.fullName` directamente al DataSource).*
*   **Respuesta Esperada:** Idéntica a la respuesta de Login (`UserModel` con tokens).

### 4.3. Refresco de Sesión
*   **Método:** `POST`
*   **Path sugerido:** `/api/v1/auth/refresh`
*   **Request Body:**
    ```json
    {
      "refreshToken": "dGhpcyBp..."
    }
    ```
*   **Respuesta Esperada:** Idéntica a la respuesta de Login (`UserModel` actualizado con nuevos tokens).

### 4.4. Cierre de Sesión (Logout)
*   **Método:** `POST`
*   **Path sugerido:** `/api/v1/auth/logout`
*   **Request Body:**
    ```json
    {
      "accessToken": "eyJhbGci..."
    }
    ```
    *(O vía Header `Authorization: Bearer <token>`)*.
*   **Respuesta Esperada:** Código HTTP 200/204. No se espera body (`Future<void>`).

---

## 5. Convenciones Generales y Comunicación

1. **Formato JSON (Casing):** El modelo `UserModel.fromJson()` en Flutter espera campos en **snake_case** (ej. `full_name`, `access_token`, `created_at`). 
2. **Fechas:** Siempre en ISO 8601 UTC. El cliente utiliza `DateTime.tryParse()` nativo de Dart.
3. **Manejo Offline-First:** El cliente almacena la sesión localmente en `Hive`. Si el backend responde exitosamente con los tokens, el frontend cacheará toda la entidad para permitir inicios de sesión locales sin conexión.
4. **Envoltura de Respuesta:** El `AuthRemoteDataSource` en Flutter actualmente no asume una envoltura global tipo `{"data": {...}}`. Espera que el objeto JSON del usuario sea la raíz de la respuesta (ver `UserModel.fromJson(Map<String, dynamic> json)`).

---

## 6. Fuera del Alcance de este Microservicio

Este documento es exclusivamente para Autenticación y Gestión de Usuarios. El equipo de backend **NO** debe incluir en este servicio:
*   Gestión de Parcelas y Terrenos.
*   Lógica de Diagnóstico IA o historial de enfermedades.
*   Suscripciones (Plan Pro, Pagos).
*   Agendas de Tratamiento o "Rutas del Cultivo".

Dichos dominios pertenecen a otros módulos definidos en la arquitectura (ej. `HomeRepository`, `DiagnosisRepository`, `TreatmentRepository`).

---

## 7. Checklist de Integración para Backend

- [ ] Las fechas se devuelven estrictamente como strings ISO 8601 UTC.
- [ ] El campo `id` es un UUID (string), no un autoincremental entero.
- [ ] La respuesta JSON de usuario utiliza **snake_case** (`full_name`, `access_token`, etc.).
- [ ] Las validaciones de `username` (solo alfanuméricos y guión bajo, min 3 chars) están activas en el servidor.
- [ ] El login y registro devuelven el shape exacto de `UserModel` con los tokens.
- [ ] Los campos opcionales (`email`, `phone`, `avatar_url`) pueden ser nulos de forma segura en la base de datos y la respuesta JSON.
