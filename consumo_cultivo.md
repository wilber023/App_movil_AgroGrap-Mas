# Microservicio de Cultivos — AgroGraph-MAS

Microservicio en **FastAPI + PostgreSQL + Redis**, dockerizado, que sirve el catálogo de cultivos, su metadata para IA (datos, no inferencia) y la sincronización offline. **No tiene su propio sistema de login**: confía en los tokens JWT emitidos por el **microservicio de Usuarios**, usando una clave secreta compartida (`JWT_SECRET_KEY`).

📄 **Documentación de consumo del API:** [`docs/CONSUMO_API.md`](docs/CONSUMO_API.md)

---

## Cómo se conecta este microservicio con el de Usuarios

Esta es la pieza más importante a entender antes de desplegar:

### 1. Autenticación de usuarios (agricultor / aprendiz_agricola / admin) — vía JWT compartido

Este microservicio **no tiene endpoint de login ni tabla de usuarios**. Cuando la app Flutter llama a un endpoint de Cultivos, sigue enviando el mismo `access_token` que ya obtuvo del microservicio de Usuarios:

```
Authorization: Bearer <access_token_emitido_por_usuarios>
```

Cultivos decodifica ese token usando **la misma `JWT_SECRET_KEY`** que tiene configurada el microservicio de Usuarios. Si la firma es válida, Cultivos confía en que ese token fue legítimamente emitido por Usuarios — **sin necesidad de hacer ninguna llamada de red entre los dos servicios** en cada request. De ahí sale el `id` del usuario (`sub`) y su rol (`role`), usados para aplicar los permisos correspondientes.

> 🔑 **La "palabra reservada" que pediste es exactamente esto:** `JWT_SECRET_KEY`. Debe tener **el valor idéntico, carácter por carácter**, en el `.env` de **ambos** microservicios. Si no coincide, Cultivos rechazará con `401` cualquier token, aunque el usuario sí haya iniciado sesión correctamente en Usuarios.

### 2. Llamadas microservicio-a-microservicio (sin usuario de por medio) — vía API Key de servicio

Para cuando, en el futuro, otro microservicio interno (por ejemplo, el de LLM que generará el plan del aprendiz) necesite llamar a Cultivos **sin que haya un humano autenticado**, existe un segundo mecanismo, independiente del JWT:

```
X-Service-Key: <SERVICE_API_KEY>
```

Esta clave (`SERVICE_API_KEY`) es distinta de `JWT_SECRET_KEY` y solo la usan los microservicios entre sí, nunca el cliente Flutter.

| Mecanismo | Header | Quién lo usa | Clave compartida |
|---|---|---|---|
| JWT de usuario | `Authorization: Bearer <token>` | App Flutter (usuario humano autenticado) | `JWT_SECRET_KEY` (igual en Usuarios y Cultivos) |
| API Key de servicio | `X-Service-Key: <key>` | Otros microservicios internos (server-to-server) | `SERVICE_API_KEY` (definida solo en Cultivos por ahora) |

---

## Permisos por rol en este microservicio

| Acción | agricultor | aprendiz_agricola | admin |
|---|---|---|---|
| Ver catálogo de cultivos | Sí | Sí | Sí |
| Ver detalle de un cultivo | Sí | Sí | Sí |
| Seleccionar un cultivo (`POST /selecciones`) | Sí | Sí | No aplica |
| Ver metadata IA (`ia-metadata`, `disease-labels`, `prompts`) | Sí | No | Sí |
| Descargar modelo CNN / embeddings / top-k | Sí (pendiente de implementación) | No | Sí |
| Sincronización offline (`/sync/*`) | Sí | Sí | Sí |
| Crear / editar / eliminar cultivos | No | No | Sí |

> El **aprendiz_agricola** está limitado intencionalmente a "ver catálogo + seleccionar cultivo", como acordamos. La generación del plan vía LLM a partir de esa selección **no está implementada en este microservicio** — vivirá en un futuro microservicio de IA/LLM, que podrá leer la selección guardada aquí usando el endpoint protegido con `X-Service-Key` (`GET /selecciones/usuario/{usuario_id}/actual`).

---

## Stack

- **FastAPI** (Python 3.12)
- **PostgreSQL 16** — base de datos propia de este microservicio (independiente de la de Usuarios)
- **Redis 7** — reservado para caché de catálogo (no se usa todavía para sesiones, ya que este servicio no las maneja)
- **SQLAlchemy 2 (async) + Alembic**
- **Docker / Docker Compose**

---

## Estructura del proyecto

```
microservicio-cultivos/
├── app/
│   ├── api/
│   │   ├── deps.py            # Verificación de JWT compartido + API Key de servicio + roles
│   │   └── v1/
│   │       ├── cultivos.py     # CRUD de catálogo + metadata IA
│   │       ├── selecciones.py  # Selección de cultivo (flujo aprendiz/agricultor)
│   │       ├── sync.py         # Sincronización offline
│   │       └── router.py
│   ├── core/
│   │   ├── config.py
│   │   └── security.py         # Decodifica JWT (no los crea) + valida API Key de servicio
│   ├── db/
│   │   ├── session.py
│   │   └── seed.py             # Seed de los 15 cultivos del MVP
│   ├── models/
│   │   ├── cultivo.py
│   │   └── seleccion.py
│   ├── schemas/
│   │   ├── cultivo.py
│   │   └── seleccion.py
│   ├── services/
│   │   ├── cultivo_service.py
│   │   └── seleccion_service.py
│   └── main.py
├── alembic/
├── docs/
│   └── CONSUMO_API.md
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── requirements.txt
└── .env.example
```

---

## 1. Levantar el proyecto

Este microservicio está pensado para correr en una **instancia EC2 separada** de la de Usuarios (no comparten red Docker ni VPC). Cada uno usa su propia red Docker local:

```yaml
networks:
  agrograph_net:
    driver: bridge
    name: agrograph_cultivos_net
```

No necesitas que Usuarios esté corriendo en esta misma instancia. La comunicación entre ambos microservicios (la validación del JWT) ocurre por la clave compartida `JWT_SECRET_KEY`, **no por red Docker** — así que esto funciona perfectamente con instancias completamente independientes, cada una con su propia IP pública.

### Pasos para levantar Cultivos

```bash
cd microservicio-cultivos
cp .env.example .env
```

Edita `.env` y completa, como mínimo:

```dotenv
POSTGRES_PASSWORD=otra_password_segura_para_cultivos
DATABASE_URL=postgresql+asyncpg://agrograph_cultivos_user:otra_password_segura_para_cultivos@db_cultivos:5432/agrograph_cultivos

# CRÍTICO: debe ser IDÉNTICO al JWT_SECRET_KEY del .env de microservicio-usuarios,
# sin importar que cada uno corra en su propia instancia EC2.
JWT_SECRET_KEY=<el mismo valor exacto que usaste en microservicio-usuarios/.env>

# Clave nueva, solo para llamadas servicio-a-servicio (genera una distinta a JWT_SECRET_KEY)
SERVICE_API_KEY=<genera con: openssl rand -hex 32>

# IP pública (o dominio) de la instancia donde corre Usuarios, sin puerto si ya
# tiene Nginx delante (ver sección "Exponer sin el puerto", más abajo)
USUARIOS_SERVICE_URL=http://<IP_PUBLICA_INSTANCIA_USUARIOS>
```

> ⚠️ El paso más fácil de olvidar: **copia el valor exacto de `JWT_SECRET_KEY`** desde `microservicio-usuarios/.env` a `microservicio-cultivos/.env`. Si generas uno nuevo "por separado", los tokens dejarán de funcionar entre microservicios.

```bash
docker compose up --build -d
docker compose logs -f api_cultivos
```

### Verificar que todo funciona

```bash
curl http://localhost:8001/health
# {"status":"ok","service":"AgroGraph-Cultivos"}
```

Swagger UI: `http://localhost:8001/docs`

### Probar la conexión entre ambos microservicios (extremo a extremo)

Usa la IP pública de cada instancia:

```bash
# 1. Login en el microservicio de Usuarios (otra instancia)
curl -X POST http://<IP_PUBLICA_INSTANCIA_USUARIOS>:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "TU_USUARIO", "password": "TU_PASSWORD"}'

# Copia el "access_token" de la respuesta

# 2. Usa ESE MISMO token contra el microservicio de Cultivos (esta instancia)
curl -X GET http://<IP_PUBLICA_INSTANCIA_CULTIVOS>:8001/api/v1/cultivos \
  -H "Authorization: Bearer <ACCESS_TOKEN_DEL_PASO_1>"
```

Si esto devuelve el catálogo de 15 cultivos sin error 401, la conexión entre ambos microservicios vía `JWT_SECRET_KEY` compartida está funcionando correctamente — el JWT viaja dentro de la petición HTTP normal del cliente, las instancias nunca necesitan conocerse ni llamarse entre sí para esto.

---

## 2. Despliegue en AWS EC2

Esta instancia es **independiente** de la de Usuarios — lanza una instancia EC2 nueva siguiendo el mismo patrón que la de Usuarios (Ubuntu 24.04, Docker instalado igual). Lo específico de Cultivos:

```bash
# En la NUEVA instancia EC2, dedicada a Cultivos
cd ~
git clone <URL_REPO_CULTIVOS>
cd microservicio-cultivos

cp .env.example .env
nano .env   # Copia el MISMO JWT_SECRET_KEY que usaste en microservicio-usuarios/.env

docker compose up --build -d
```

### Security Group de esta instancia

| Tipo | Protocolo | Puerto | Origen |
|---|---|---|---|
| SSH | TCP | `22` | Tu IP |
| Custom TCP | TCP | `8001` | `0.0.0.0/0` (o restringido) |

### Flujo de actualización (`git pull`)

Idéntico al de Usuarios:

```bash
cd microservicio-cultivos
git pull origin main
docker compose up --build -d
```

---

## 2.1 Exponer la API sin el puerto `:8001` (Nginx)

Igual que se hizo con Usuarios, puedes poner Nginx delante de Cultivos para que la URL final no necesite el puerto:

```bash
sudo apt-get update
sudo apt-get install -y nginx
sudo nano /etc/nginx/sites-available/agrograph-cultivos
```

Contenido (ajusta la IP a la de **esta** instancia, la de Cultivos):

```nginx
server {
    listen 80;
    server_name <IP_PUBLICA_DE_ESTA_EC2_CULTIVOS>;

    location / {
        proxy_pass http://localhost:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Activar y reiniciar:

```bash
sudo ln -s /etc/nginx/sites-available/agrograph-cultivos /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

Abre el puerto `80` en el Security Group de esta instancia (regla `HTTP`, `0.0.0.0/0`).

Con esto, la URL final de Cultivos pasa de `http://<IP_CULTIVOS>:8001` a simplemente `http://<IP_CULTIVOS>` — igual que ya quedó Usuarios.

| Microservicio | URL sin Nginx | URL con Nginx |
|---|---|---|
| Usuarios | `http://<IP_USUARIOS>:8000` | `http://<IP_USUARIOS>` |
| Cultivos | `http://<IP_CULTIVOS>:8001` | `http://<IP_CULTIVOS>` |

Si ambas instancias ya tienen Nginx, el flujo extremo a extremo queda así, sin puertos:

```bash
# 1. Login en Usuarios
curl -X POST http://<IP_USUARIOS>/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "TU_USUARIO", "password": "TU_PASSWORD"}'

# 2. Usar ese token contra Cultivos
curl -X GET http://<IP_CULTIVOS>/api/v1/cultivos \
  -H "Authorization: Bearer <ACCESS_TOKEN>"
```

Y actualiza también la variable de referencia en el `.env` de Cultivos para que quede sin puerto:

```dotenv
USUARIOS_SERVICE_URL=http://<IP_USUARIOS>
```

---

## 3. Variables de entorno críticas

| Variable | Por qué es crítica |
|---|---|
| `JWT_SECRET_KEY` | **Debe ser idéntica** a la del microservicio de Usuarios. Es lo que conecta ambos servicios |
| `SERVICE_API_KEY` | Protege endpoints internos pensados para otros microservicios (ej. futuro LLM) |
| `POSTGRES_PASSWORD` / `DATABASE_URL` | Credenciales de la base de datos propia de Cultivos |
| `USUARIOS_SERVICE_URL` | Referencia informativa a la URL del microservicio de Usuarios (sin puerto si ya tiene Nginx delante). No se usa todavía en ninguna llamada real del código |

---

## 4. El catálogo inicial (seed automático)

Al levantar el contenedor por primera vez (tabla `cultivos` vacía), se cargan automáticamente los 15 cultivos del MVP: Calabaza, Frijol, Manzana, Mora, Cereza, Maíz, Durazno, Uva, Naranja, Pimienta, Papa, Frambuesa, Soja, Fresa y Tomate — con valores razonables por defecto. El admin puede refinarlos después vía `PATCH /api/v1/cultivos/{id}`.

---

## 5. Lo que falta para el flujo completo del aprendiz (próximas iteraciones)

Este microservicio deja lista la base (catálogo + selección), pero **no genera el plan**. Cuando construyas el microservicio de LLM:

1. El aprendiz selecciona un cultivo -> `POST /api/v1/selecciones` (ya implementado aquí).
2. El microservicio de LLM consulta esa selección -> `GET /api/v1/selecciones/usuario/{usuario_id}/actual` con header `X-Service-Key` (ya implementado aquí, listo para ser consumido).
3. El microservicio de LLM genera el plan y se lo entrega al cliente (a implementar en ese nuevo servicio).
