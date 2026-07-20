# README — Integración Frontend: Registro de Siembra del Aprendiz Agrícola

> Dirigido al equipo Flutter. Responde `README_BACKEND_CULTIVOS_APRENDIZ.md` (el que ustedes escribieron): esto es lo que quedó **implementado y desplegado en producción** en el microservicio de Cultivos, listo para consumir.

---

## 1. Qué se implementó

Se tomó la **Opción A** (recomendada en su README): se extendió `POST /selecciones` — el mismo endpoint que ya usa el Agricultor — en vez de crear un namespace `/aprendiz/...` separado. No se tocó nada del contrato existente para `agricultor`; solo se agregaron campos nuevos, todos opcionales.

**Ya NO necesitan** seguir apuntando `CropPlanRemoteDataSourceImpl` al microservicio de Usuarios (`174.129.218.190`, endpoint `// TODO`). Este microservicio de Cultivos es ahora la fuente de verdad también para el Aprendiz.

---

## 2. Conexión

| | Valor |
|---|---|
| **Base URL** | `http://3.217.217.227/api/v1` (vía Nginx, puerto 80) — equivalente a `http://3.217.217.227:8001/api/v1` directo al contenedor |
| **Docs interactivas** | `http://3.217.217.227/docs` |
| **Auth** | Mismo `access_token` (JWT) que ya emite el microservicio de Usuarios — no hay login propio aquí |
| **Header** | `Authorization: Bearer <access_token>` |

Usen el mismo Dio dedicado a Cultivos que ya existe en el cliente para el flujo Agricultor: `cultivosDio` (`lib/core/di/injection_container.dart`, función `_initParcelsFeature`), que ya trae los interceptores de auth configurados.

---

## 3. Respuestas a las preguntas abiertas de su README (sección 6)

| # | Pregunta | Respuesta |
|---|---|---|
| 1 | ¿Los 5 cultivos ya existen en el catálogo con `id` estable? | **Sí.** `Calabaza`, `Frijol`, `Maíz`, `Papa`, `Tomate` ya están seedeados en `/cultivos` con UUID estable (junto con otros 10 cultivos del catálogo MVP). Consulten `GET /api/v1/cultivos` y filtren/mapeen por `slug` (`calabaza`, `frijol`, `maiz`, `papa`, `tomate`) para obtener el `id` real. |
| 2 | ¿Opción A o B? | **Opción A** — se extendió `POST /selecciones`, no se creó endpoint separado. |
| 3 | ¿`lugar_practica` en español o inglés? | **Español**: `"jardin_casa"` \| `"invernadero"`. El cliente debe mapear su enum `CropPracticeLocation` (`home`/`greenhouse`) a estos strings antes de enviar. |
| 4 | ¿Este microservicio generará el plan de actividades? | **Aún no** — sigue pendiente de decisión de producto, tal como lo marcaron como "no bloqueante" en la sección 5 de su README. `GET /selecciones/{id}/actividades` **no existe todavía**. El cliente debe seguir mostrando el plan vacío por ahora. |
| 5 | ¿`nombre_parcela` sigue siendo parte del modelo para el Aprendiz? | El campo sigue existiendo en el modelo, pero es **opcional** para el Aprendiz: si no lo envían, el backend autogenera `"Cultivo de práctica"` como valor por defecto. No necesitan enviarlo ni mostrarlo en el formulario del Aprendiz. |

---

## 4. Contrato implementado

### 4.1 Registrar el cultivo de práctica

```
POST /api/v1/selecciones
Authorization: Bearer <jwt aprendiz_agricola>
Content-Type: application/json
```

**Request body — únicamente estos 3 campos son necesarios para el Aprendiz:**

```json
{
  "cultivo_id": "uuid-del-cultivo-maiz",
  "fecha_siembra": "2026-08-01",
  "lugar_practica": "jardin_casa"
}
```

- `cultivo_id`: **obligatorio**, debe ser el `id` real de uno de los 5 cultivos del catálogo (ver sección 3, pregunta 1).
- `fecha_siembra`: opcional a nivel de schema, pero su formulario ya lo captura siempre — envíenlo como `YYYY-MM-DD`.
- `lugar_practica`: opcional a nivel de schema; enum `"jardin_casa"` \| `"invernadero"`. Cualquier otro valor devuelve `422`.
- No envíen `nombre_parcela`, `area_ha`, `unidad_area`, `region`, `terreno_tipo`, `suelo_condiciones`, `maleza_tipos` — no aplican al flujo del Aprendiz (el backend los deja `null`/con default).

**Respuesta (`201 Created`):**

```json
{
  "id": "uuid-seleccion",
  "usuario_id": "uuid-del-usuario",
  "usuario_role": "aprendiz_agricola",
  "cultivo_id": "uuid-del-cultivo-maiz",
  "cultivo_nombre": "Maíz",
  "cultivo_slug": "maiz",
  "nombre_parcela": "Cultivo de práctica",
  "area_ha": null,
  "unidad_area": "ha",
  "region": null,
  "fecha_siembra": "2026-08-01",
  "terreno_tipo": null,
  "suelo_condiciones": null,
  "maleza_tipos": null,
  "lugar_practica": "jardin_casa",
  "etapa_fenologica": "Siembra",
  "progreso_etapa": 0,
  "estado_salud": "Sin diagnostico",
  "estado_plan": "activo",
  "created_at": "2026-08-01T00:00:00Z"
}
```

**Errores:**
- `404` — `cultivo_id` no existe en el catálogo.
- `400` — el cultivo existe pero no está `activo`.
- `401` — token inválido/expirado.
- `403` — el rol del token no es `agricultor` ni `aprendiz_agricola`.
- `422` — body inválido (ej. `lugar_practica` con un valor fuera del enum, `cultivo_id` no es UUID válido).

### 4.2 Recuperar los cultivos de práctica del usuario (tras reinstalar, etc.)

```
GET /api/v1/selecciones/mis-selecciones
Authorization: Bearer <jwt>
```

Devuelve un arreglo con el mismo shape de 4.1, más recientes primero, filtrado automáticamente por el `sub` del JWT (no manden `usuario_id`). Incluye `lugar_practica` en cada elemento cuando aplica.

---

## 5. Cambios sugeridos en el cliente (mapeo a su propio README, sección 8)

| Archivo | Cambio necesario |
|---|---|
| `lib/features/aprendiz/cultivo/data/datasources/crop_plan_remote_datasource.dart` | Migrar de `ApiClient` (Usuarios) a `cultivosDio` (Cultivos), apuntando a `POST /api/v1/selecciones` y `GET /api/v1/selecciones/mis-selecciones` en lugar del endpoint fantasma `/aprendiz/crop-plan`. |
| `lib/features/aprendiz/cultivo/presentation/pages/aprendiz_crop_register_page.dart` | El paso 1 ("¿Qué vas a sembrar?") debe dejar de mandar el nombre libre del cultivo y en su lugar resolver el `cultivo_id` real vía `GET /cultivos` (filtrando por los 5 `slug` fijos), igual que ya hace el flujo Agricultor. |
| `lib/features/aprendiz/cultivo/domain/entities/crop_practice_location.dart` | Al serializar, mapear `CropPracticeLocation.home` → `"jardin_casa"` y `.greenhouse` → `"invernadero"` (en vez de `.name` en inglés). |
| `lib/features/aprendiz/cultivo/domain/entities/crop_plan_entity.dart` | El plan de actividades (`CropActivityEntity`) **sigue sin backend real** — no hay cambios aquí todavía; pueden seguir mostrando la lista vacía hasta que se decida quién genera el plan (sección 3, pregunta 4). |
| Fallback local en Hive (`isPendingSync: true`) | Puede eliminarse una vez migrado el datasource — el registro ya persiste de verdad en el backend. |

---

## 6. Ejemplo de flujo completo (curl)

```bash
# 1. Login en Usuarios (sin cambios)
curl -X POST http://174.129.218.190:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "aprendiz_demo", "password": "mypassword123"}'

# 2. Obtener el id real de "Maíz" del catálogo
curl -s http://3.217.217.227/api/v1/cultivos?categoria=cereal \
  -H "Authorization: Bearer <ACCESS_TOKEN>"
# -> tomar el "id" del elemento con "slug": "maiz"

# 3. Registrar el cultivo de práctica
curl -X POST http://3.217.217.227/api/v1/selecciones \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "cultivo_id": "<ID_DE_MAIZ>",
    "fecha_siembra": "2026-08-01",
    "lugar_practica": "jardin_casa"
  }'

# 4. Recuperar lo registrado (ej. al reabrir la app)
curl -X GET http://3.217.217.227/api/v1/selecciones/mis-selecciones \
  -H "Authorization: Bearer <ACCESS_TOKEN>"
```

---

## 7. Fuera de alcance (por ahora)

El **plan de actividades semanal** ("Mi Cultivo": semana actual, progreso, tareas) que documentaron en la sección 5 de su README **no se implementó en este cambio** — quedó marcado explícitamente como no bloqueante. Si lo necesitan pronto, es una conversación de producto aparte (quién lo genera: este microservicio por plantilla, o un servicio distinto).
