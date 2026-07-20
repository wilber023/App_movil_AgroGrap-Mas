# README — Nuevo endpoint para registro de siembra del perfil Aprendiz

> Dirigido al equipo backend responsable del **microservicio de Cultivos** (`http://3.217.217.227:8001`, expuesto vía Nginx en `http://3.217.217.227/api/v1`).
> Objetivo: documentar exactamente qué necesita el cliente Flutter para que el perfil **Aprendiz Agrícola** registre su cultivo de práctica ("voy a sembrar X, el día Y, en Z") contra este microservicio, reutilizando lo que ya existe para el perfil Agricultor en vez de duplicar backend.

---

## 1. Resumen del problema

La app tiene dos perfiles de usuario: **Agricultor** y **Aprendiz Agrícola**. Ambos, en algún punto de su flujo, "registran un cultivo que van a sembrar". Hoy eso está resuelto de dos formas completamente distintas y desconectadas:

| | Agricultor (`lib/features/agricultor/parcels/`) | Aprendiz (`lib/features/aprendiz/cultivo/`) |
|---|---|---|
| Backend usado | **Este microservicio de Cultivos** (`3.217.217.227:8001`) | Microservicio de Usuarios (`174.129.218.190`), endpoint `POST /aprendiz/crop-plan` marcado `// TODO` en el cliente — **no confirmado, probablemente inexistente** |
| Selección de cultivo | Catálogo real vía `GET /cultivos`, usa `cultivo_id` real | 5 nombres de cultivo **hardcodeados en el cliente**, sin `id` |
| Payload al crear | `cultivo_id`, `nombre_parcela`, `area_ha`, `unidad_area`, `region`, `fecha_siembra`, `terreno_tipo?`, `suelo_condiciones?`, `maleza_tipos?` | `cropName` (texto libre), `startDate`, `practiceLocation` |
| Campo "dónde siembra" | `terreno_tipo`: Plano / Pendiente ligera / Pendiente pronunciada | `practiceLocation`: **Jardín en casa / Invernadero** (concepto distinto, no existe en el lado Agricultor) |
| Estado real | Funciona en producción | Como el endpoint no existe, el cliente cae siempre a un fallback local: guarda el "plan" en Hive con `activities: []` y `isPendingSync: true` — el aprendiz nunca ve un plan de actividades real |

**Lo que se pide a este equipo**: crear (o extender) un endpoint en este microservicio para que el registro de siembra del Aprendiz se guarde aquí, de forma consistente con `/selecciones` (que ya usa el Agricultor), en lugar de seguir apuntando a un endpoint fantasma en otro microservicio.

---

## 2. Lo que ya existe hoy en este microservicio (reutilizable, confirmado funcionando)

Todo lo siguiente ya está integrado y en uso por el perfil Agricultor — se documenta aquí como base de la propuesta.

### 2.1 Catálogo de cultivos
```
GET /api/v1/cultivos
GET /api/v1/cultivos/{id}
```
Modelo `Cultivo` consumido por el cliente:
```json
{
  "id": "uuid",
  "nombre": "Maíz",
  "descripcion": "string opcional",
  "familia": "string opcional",
  "tipo_cultivo": "string opcional",
  "imagen_url": "string opcional"
}
```
El cliente tolera variantes `familia`/`categoria`, `tipo_cultivo`/`tipoCultivo`/`categoria`, `imagen_url`/`imagenUrl`.

### 2.2 Selecciones ("voy a sembrar este cultivo")
```
POST   /api/v1/selecciones
GET    /api/v1/selecciones/mis-selecciones
DELETE /api/v1/selecciones/{id}
```

Body de `POST /selecciones` que envía hoy el cliente Agricultor:
```json
{
  "cultivo_id": "uuid",
  "nombre_parcela": "Milpa Norte",
  "area_ha": 2.5,
  "unidad_area": "ha",
  "region": "Ocosingo, Chiapas",
  "fecha_siembra": "2026-03-15",
  "terreno_tipo": "Pendiente ligera",
  "suelo_condiciones": ["Húmedo", "Arcilloso"],
  "maleza_tipos": ["Pastos"]
}
```
`terreno_tipo`, `suelo_condiciones` y `maleza_tipos` ya se envían como opcionales (el cliente solo los incluye si el usuario los llenó).

Respuesta esperada por el cliente (`GET /selecciones/mis-selecciones`, tolera snake_case o camelCase):
```json
{
  "id": "uuid",
  "cultivo_id": "uuid",
  "cultivo_nombre": "Maíz",
  "nombre_parcela": "Milpa Norte",
  "area_ha": 2.5,
  "unidad_area": "ha",
  "region": "Ocosingo, Chiapas",
  "fecha_siembra": "2026-03-15",
  "etapa_fenologica": "Vegetativo",
  "progreso_etapa": 45,
  "estado_salud": "Saludable"
}
```

### 2.3 Autenticación
- Mismo JWT que emite el microservicio de Usuarios (clave compartida `JWT_SECRET_KEY`). El cliente manda `Authorization: Bearer <token>`.
- El backend ya filtra "mis selecciones" por el claim `sub` del JWT — el cliente no manda `userId` explícito.
- El JWT trae un claim de **rol** (`rol: "agricultor" | "aprendiz_agricola"`) — ya se usa hoy en el microservicio LLM para diferenciar tono de respuesta, así que el mecanismo para leer el rol desde el token ya existe en el ecosistema.

---

## 3. Lo que pide registrar el Aprendiz (formulario real, ya implementado en el cliente)

Pantalla `AprendizCropRegisterPage`, 3 pasos, los 3 obligatorios:

1. **¿Qué vas a sembrar?** — grid de selección única entre **exactamente 5 cultivos fijos**: `Calabaza`, `Frijol`, `Maíz`, `Papa`, `Tomate`. (Este límite de 5 viene del modelo CNN de diagnóstico por imagen, no de una regla de negocio de este microservicio — pero son cultivos agrícolas normales, así que deberían poder existir ya en el catálogo `/cultivos`.)
2. **Fecha de siembra** — date picker, rango 2020-01-01 a 31/dic del año siguiente.
3. **¿Dónde vas a practicar?** — selección única entre exactamente 2 opciones:
   - `home` → "Jardín en casa"
   - `greenhouse` → "Invernadero"

No se piden (a diferencia del formulario de Agricultor): nombre de parcela, área/hectáreas, región, tipo de terreno, condición de suelo, malezas. El formulario del Aprendiz es intencionalmente más simple — es un cultivo de práctica, no una parcela de producción real.

Enum del cliente (`CropPracticeLocation`), serializado como `.name` en inglés hoy: `"home"` / `"greenhouse"`. **Este valor es negociable** — si el backend prefiere español (`jardin_casa` / `invernadero`), el cliente puede mapear el enum a esos strings antes de enviarlo; solo hace falta que backend confirme el contrato exacto.

---

## 4. Propuesta técnica

### Opción A (recomendada) — Extender `POST /selecciones` para aceptar un contexto de Aprendiz

Ventaja: una sola tabla/entidad "selección", un solo endpoint de escritura, reutiliza toda la lógica de autenticación, catálogo y consulta ya construida. El backend ya distingue el rol vía JWT, así que puede decidir server-side qué campos son obligatorios según `rol`.

**Cambios propuestos al contrato de `POST /selecciones`:**

- Agregar campo opcional `lugar_practica` (enum: `jardin_casa` | `invernadero`), aplicable solo cuando el rol del JWT es `aprendiz_agricola`.
- Hacer opcionales para rol `aprendiz_agricola`: `nombre_parcela` (autogenerar un default tipo `"Cultivo de práctica"` si no viene), `area_ha`, `unidad_area`, `region`, `terreno_tipo`. Para `agricultor` estos campos siguen siendo obligatorios como hoy.
- Campos que el Aprendiz sí siempre manda: `cultivo_id`, `fecha_siembra`.

Ejemplo de request que el cliente Aprendiz enviaría:
```json
POST /api/v1/selecciones
Authorization: Bearer <jwt aprendiz_agricola>
Content-Type: application/json

{
  "cultivo_id": "uuid-del-cultivo-maiz",
  "fecha_siembra": "2026-08-01",
  "lugar_practica": "jardin_casa"
}
```

Respuesta esperada (mismo shape que hoy, con el nuevo campo):
```json
{
  "id": "uuid-seleccion",
  "cultivo_id": "uuid-del-cultivo-maiz",
  "cultivo_nombre": "Maíz",
  "nombre_parcela": "Cultivo de práctica",
  "fecha_siembra": "2026-08-01",
  "lugar_practica": "jardin_casa",
  "etapa_fenologica": "Siembra",
  "progreso_etapa": 0,
  "estado_salud": "Sin diagnostico"
}
```

`GET /selecciones/mis-selecciones` seguiría funcionando igual para el Aprendiz (filtrado por `sub` del JWT), devolviendo también `lugar_practica` cuando aplique.

### Opción B — Endpoint dedicado `POST /aprendiz/selecciones`

Si el equipo prefiere no tocar el contrato existente de `/selecciones` (por ejemplo, para no arriesgar al cliente Agricultor en producción), la alternativa es un endpoint hermano con el mismo mecanismo de auth y catálogo, pero payload reducido:

```
POST /api/v1/aprendiz/selecciones
GET  /api/v1/aprendiz/selecciones/mis-selecciones
```
Mismo body que el ejemplo de la Opción A. Internamente puede mapear a la misma tabla `selecciones` con `lugar_practica` nullable, o a una tabla separada — es decisión del equipo backend, el cliente solo necesita el contrato HTTP.

**Recomendación**: Opción A si el volumen de cambio es manejable; Opción B si se prefiere aislar el riesgo. Cualquiera de las dos resuelve el problema del cliente.

---

## 5. Brecha crítica adicional: el "plan de actividades" no existe en ningún lado

Esto es importante para que el equipo backend dimensione correctamente el trabajo, no solo el endpoint de registro:

El cliente tiene una pantalla "Mi Cultivo" (`AprendizCropRoutePage`) que muestra un plan por semanas: etapa actual, semana actual (`currentWeek`), porcentaje de progreso, y una lista de actividades (`CropActivityEntity`: título, descripción, semana, fecha programada, estado `pending|completed|postponed`). **Hoy nada genera esas actividades** — ni el cliente (no hay motor de plantillas local) ni ningún backend real. El resultado actual es que todo aprendiz que registra un cultivo ve "Semana 1 de 18, 0% de progreso" para siempre, sin ninguna tarea.

Si este microservicio va a ser la fuente de verdad del registro de siembra del Aprendiz, tiene sentido (aunque es una decisión de producto, no solo técnica) que también sea quien genere el plan de actividades por plantilla al crear la selección — sin IA, como ya describe la documentación de diseño interna (`flujo_aprendiz.md`): un set fijo de actividades por cultivo/semana (inspección, riego, fertilización, cosecha estimada), similar a como ya se calcula `etapa_fenologica`/`progreso_etapa` para el Agricultor.

Estructura sugerida si se decide incluirlo en el mismo endpoint (`POST /selecciones` devolvería el plan embebido, o se expondría aparte):

```json
GET /api/v1/selecciones/{id}/actividades
[
  {
    "id": "uuid",
    "titulo": "Inspección semanal",
    "descripcion": "Revisa el estado de las hojas y busca signos de enfermedad",
    "semana": 1,
    "fecha_programada": "2026-08-08",
    "estado": "pending"
  }
]
```
Y un endpoint para completar/posponer, análogo a lo que el cliente ya tiene modelado (hoy sin backend real): `PATCH /api/v1/selecciones/{seleccionId}/actividades/{actividadId}` con `{"estado": "completed" | "postponed"}`.

**Esto no es un bloqueante para lanzar el endpoint de registro** — el cliente puede seguir mostrando un plan vacío mientras se decide esta parte — pero se documenta aquí porque es la causa raíz de que la feature "Mi Cultivo" del Aprendiz esté hoy prácticamente inutilizable, y probablemente el equipo de producto lo pida como siguiente paso inmediato.

---

## 6. Preguntas abiertas para resolver con backend antes de implementar

1. ¿Los 5 cultivos (`Calabaza`, `Frijol`, `Maíz`, `Papa`, `Tomate`) ya existen como registros en el catálogo `/cultivos` con `id` estable? El cliente necesita esos IDs para dejar de mandar nombres libres y empezar a usar `cultivo_id` real (alineado con cómo ya trabaja el flujo Agricultor).
2. ¿Opción A o B de la sección 4? ¿Se prefiere extender `/selecciones` o crear un namespace `/aprendiz/...` separado?
3. ¿`lugar_practica` se acepta en español (`jardin_casa`/`invernadero`) o el backend prefiere que el cliente siga mandando los valores en inglés del enum actual (`home`/`greenhouse`)?
4. ¿Este microservicio asumirá también la generación del plan de actividades (sección 5), o esa responsabilidad se queda en otro lado (p. ej. un servicio de "planes" separado, o se resuelve client-side con plantillas locales)?
5. ¿El campo `nombre_parcela` debe seguir siendo parte del modelo para selecciones de Aprendiz, o tiene sentido que el backend lo omita/autogenere ya que el Aprendiz no gestiona parcelas con nombre?

---

## 7. Contrato mínimo que desbloquea al cliente (si se necesita acotar el primer entregable)

Si se quiere avanzar rápido con lo mínimo indispensable, esto es lo único estrictamente necesario para que el cliente deje de depender del endpoint fantasma:

```
POST /api/v1/selecciones   (o /api/v1/aprendiz/selecciones)
Authorization: Bearer <jwt>

Request:
{
  "cultivo_id": "uuid",        // uno de los 5 cultivos del catálogo
  "fecha_siembra": "YYYY-MM-DD",
  "lugar_practica": "jardin_casa" | "invernadero"
}

Response 201:
{
  "id": "uuid",
  "cultivo_id": "uuid",
  "cultivo_nombre": "Maíz",
  "fecha_siembra": "YYYY-MM-DD",
  "lugar_practica": "jardin_casa",
  "etapa_fenologica": "Siembra",
  "progreso_etapa": 0,
  "estado_salud": "Sin diagnostico"
}
```

```
GET /api/v1/selecciones/mis-selecciones   (o /api/v1/aprendiz/selecciones/mis-selecciones)
Authorization: Bearer <jwt>

Response 200: [ { ...mismo shape de arriba... } ]
```

Con esto el cliente puede: (a) migrar `AprendizCropRegisterPage` para usar `cultivo_id` real del catálogo en vez de nombre libre, (b) apuntar `CropPlanRemoteDataSourceImpl` al Dio dedicado de cultivos (`cultivosDio`, ya existente en el cliente) en vez del `ApiClient` de Usuarios, y (c) eliminar el fallback silencioso que hoy genera planes vacíos sin conexión real a backend.

---

## 8. Referencia rápida — dónde está el código del cliente involucrado

- Formulario de registro: `lib/features/aprendiz/cultivo/presentation/pages/aprendiz_crop_register_page.dart`
- Enum lugar de práctica: `lib/features/aprendiz/cultivo/domain/entities/crop_practice_location.dart`
- Entidad del plan: `lib/features/aprendiz/cultivo/domain/entities/crop_plan_entity.dart`
- Datasource remoto actual (a migrar): `lib/features/aprendiz/cultivo/data/datasources/crop_plan_remote_datasource.dart`
- Endpoints declarados: `lib/core/network/api_endpoints.dart` (clases `AprendizEndpoints`, `CultivosApiEndpoints`, `SeleccionesApiEndpoints`)
- Implementación real y funcionando del lado Agricultor (patrón a replicar): `lib/features/agricultor/parcels/data/datasources/cultivos_remote_datasource.dart`
- Dio dedicado al microservicio de cultivos, con interceptores de auth: `lib/core/di/injection_container.dart`, función `_initParcelsFeature`
