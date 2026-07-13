# AgroGraph-MAS — Guía Frontend: Clustering (Mapa Epidemiológico) y Agenda/Seguimiento

> **Para:** equipo del front (app móvil Flutter).
> **Qué cubre:** a qué rutas conectarse, cómo funcionan y qué devuelven, para
> (1) el **mapa epidemiológico** (clustering de campañas fitosanitarias) y
> (2) la **agenda/seguimiento** de tratamientos.
>
> **Fuente:** código real del backend desplegado (`52.1.110.21:8000`) y de la app.
> Verificado el 2026-07-12.

---

## 0. Resumen de estado (léelo primero)

| Módulo | ¿Backend listo? | Dónde conectarse |
|---|---|---|
| **Mapa epidemiológico (clustering)** | ✅ **SÍ, en producción** | `http://52.1.110.21:8000/api/v1/clustering/...` y `/api/v1/alertas` |
| **Agenda / seguimiento** | ✅ **SÍ, en producción** (auto-generada por rol) | `http://52.1.110.21:8000/api/v1/{agricultor\|aprendiz}/agenda` (generar/GET/complete/postpone) |

> Ambos módulos ya son consumibles. La agenda ahora la **genera el backend** por
> rol: la app llama a `POST /{rol}/agenda/generar` con el tratamiento del
> diagnóstico y el backend arma el calendario (ver Parte 2).

---

## 1. Base URL y autenticación (aplica a ambos)

- **Base URL:** `http://52.1.110.21:8000` — es el **mismo host del servicio LLM/RAG**
  (en la app: `ApiEndpoints.llmBaseUrl`). Los endpoints de clustering viven ahí.
- **Autenticación:** **JWT Bearer obligatorio** en todos los endpoints de clustering.
  ```
  Authorization: Bearer <access_token>
  ```
  El token es el mismo que emite el microservicio de **Usuarios**. Para **pruebas**,
  el backend expone un token de desarrollo (solo con `DEV_MODE=true`):
  ```bash
  curl -X POST http://52.1.110.21:8000/api/v1/dev/token \
    -H "Content-Type: application/json" \
    -d '{"sub":"test","rol":"agricultor"}'
  # → { "access_token": "eyJ...", "token_type": "bearer", "rol": "agricultor", ... }
  ```
- **Errores comunes:**
  - `401` → falta el token o está expirado/ inválido.
  - `403` → el `rol` del token no es válido.
  - `422` → parámetros mal formados.

---

## 2. PARTE 1 — Mapa Epidemiológico (Clustering) ✅ EN PRODUCCIÓN

### 2.1 Cómo funciona (por dentro)

El backend lee **datos reales de SENASICA** (archivos `datos/campanias/*.csv`, campañas
fitosanitarias) y los **agrega por entidad federativa (estado)**. No es un modelo ML:
es un *clustering por estado* que, para cada entidad, calcula:
- número de campañas activas,
- superficie atendida (ha) sumada,
- productores atendidos,
- **campaña dominante** y **cultivo dominante** (los más frecuentes en ese estado).

Los estados se devuelven **ordenados por superficie atendida (desc)**.

### 2.2 `GET /api/v1/clustering/mapa-campanias` — mapa completo por estado

Devuelve el resumen de TODOS los estados (para pintar el mapa).

**Request**
```
GET http://52.1.110.21:8000/api/v1/clustering/mapa-campanias
Authorization: Bearer <token>
```

**Response `200` (`MapaCampaniasResponse`)** — ejemplo REAL (verificado en producción, 2026-07-12; 584 campañas, 39 estados):
```json
{
  "total_campanias": 584,
  "estados": [
    {
      "estado": "Chihuahua",
      "campanias": 7,
      "superficie_ha": 170195.0,
      "productores": 2575,
      "campania_dominante": "Plagas Reglamentadas del Algodonero",
      "cultivo_dominante": "algodón"
    }
    // ... 38 estados más, ordenados por superficie_ha desc
  ]
}
```

**Campos de cada estado (`EstadoResumen`)**

| Campo | Tipo | Significado |
|---|---|---|
| `estado` | string | Entidad federativa |
| `campanias` | int | # de campañas fitosanitarias en el estado |
| `superficie_ha` | float | Superficie atendida (hectáreas), sumada |
| `productores` | int | Productores atendidos |
| `campania_dominante` | string | Campaña más frecuente en el estado |
| `cultivo_dominante` | string | Cultivo más frecuente en el estado |

### 2.3 `GET /api/v1/alertas` — alerta epidemiológica (nacional o por estado)

Devuelve la campaña dominante como "alerta". Si pasas `estado`, es la alerta de ese
estado; si lo omites, es la alerta **nacional**.

**Request**
```
GET http://52.1.110.21:8000/api/v1/alertas?estado=Chiapas
Authorization: Bearer <token>
```
> `estado` es **opcional**. Sin él → alerta nacional.

**Response `200` (`AlertaResponse`)** — ejemplo REAL (alerta **nacional**, sin `estado`, verificado en producción):
```json
{
  "hay_alerta": true,
  "estado": "Nacional",
  "mensaje": "Campaña activa a nivel nacional: Plagas de los Cítricos (naranja).",
  "campania_dominante": "Plagas de los Cítricos",
  "plaga_dominante": "Psílido Asiático de los Cítricos (Diaphorina citri)",
  "cultivo_dominante": "naranja",
  "campanias": 204,
  "superficie_ha": 106995.2
}
```

| Campo | Tipo | Nota |
|---|---|---|
| `hay_alerta` | bool | `true` si hay campaña dominante |
| `estado` | string | Estado consultado, o `"Nacional"` |
| `mensaje` | string | Texto listo para mostrar |
| `campania_dominante` | string? | opcional |
| `plaga_dominante` | string? | opcional |
| `cultivo_dominante` | string? | opcional |
| `campanias` | int? | opcional |
| `superficie_ha` | float? | opcional |

### 2.4 Ejemplo de consumo desde Flutter (Dio)

Reutiliza el `Dio` que ya apunta a `llmBaseUrl` con el `AuthInterceptor` (que inyecta
el Bearer). Los paths son relativos a `http://52.1.110.21:8000`:

```dart
// Mapa completo
final mapa = await llmDio.get('/api/v1/clustering/mapa-campanias');
// mapa.data['estados'] -> List<Map> con {estado, campanias, superficie_ha, ...}

// Alerta por estado (o nacional si se omite el query)
final alerta = await llmDio.get('/api/v1/alertas',
    queryParameters: {'estado': 'Chiapas'});
// alerta.data['mensaje'], alerta.data['hay_alerta'], ...
```

> Sugerencia: agrega estos paths a `ApiEndpoints` (ej. un `ClusteringEndpoints`)
> para no dejarlos hardcodeados en el datasource.

---

## 3. PARTE 2 — Agenda / Seguimiento ✅ EN PRODUCCIÓN (auto-generada por rol)

### 3.1 Cómo funciona

La agenda se **genera automáticamente en el backend** a partir del diagnóstico, y
existe para **ambos roles** con un **plan distinto** (porque el tratamiento ya viene
distinto por rol: agricultor práctico, aprendiz pedagógico). Flujo:

1. La app hace el diagnóstico (`POST /api/v1/consultar`) y obtiene `tratamiento` y
   `prevencion`.
2. Al pulsar **"Agregar a la agenda"**, la app llama a
   `POST /api/v1/{rol}/agenda/generar` pasándole ese tratamiento/prevención.
3. El backend arma las actividades con los **pasos reales** (fieles a los documentos)
   y le pide al **LLM solo el calendario** (qué día/semana hacer cada paso). Si el
   modelo no da un JSON válido, cae a una **regla determinista** (+2 días por paso).
   → La agenda **siempre** se genera, con contenido confiable.
4. La app **lee** con `GET` y **actualiza** con `complete` / `postpone`.

> **Base URL:** todo bajo `/api/v1`. Fija el baseUrl del Dio de agenda a
> **`http://52.1.110.21:8000/api/v1`**. **JWT Bearer** obligatorio; la agenda es
> **por (usuario, rol)** = el `sub` del token + el rol de la ruta.

> ⚠️ **Cambio en la app:** hoy el datasource solo tiene `GET`/`complete`/`postpone`
> hacia `/aprendiz/agenda`. Falta **agregar la llamada `POST .../generar`** (con el
> tratamiento del diagnóstico) y la ruta `/agricultor/agenda`. Sin llamar a
> `generar`, el `GET` de un usuario nuevo sale **vacío**.

### 3.2 Endpoints (verificados en producción 2026-07-12) — `{rol}` ∈ `agricultor | aprendiz`

| Método | Ruta (bajo `…:8000/api/v1`) | Uso |
|---|---|---|
| `POST` | `/{rol}/agenda/generar` | **Genera** la agenda desde un diagnóstico (ver body). Reemplaza la agenda previa de ese usuario+rol. |
| `GET`  | `/{rol}/agenda` | Overview (cropContext + activities). Vacío si aún no se generó. |
| `POST` | `/{rol}/agenda/activities/{activityId}/complete` | Marca `completed`. `404` si no existe. |
| `POST` | `/{rol}/agenda/activities/{activityId}/postpone` | Marca `postponed`. `404` si no existe. |

**Body de `POST /{rol}/agenda/generar`:**
```json
{
  "cultivo": "tomate",
  "enfermedad": "tizón tardío",
  "tratamiento": "- Eliminar plantas afectadas\n- Aplicar fungicida cúprico cada 7 días",
  "prevencion": "- Rotación de cultivos\n- Evitar riego por aspersión",
  "currentStage": "floración"
}
```
> Pásale el `tratamiento`/`prevencion` que ya obtuviste de `/consultar`.
> `enfermedad`, `prevencion` y `currentStage` son opcionales.

**Respuesta de `generar` y de `GET` (`AgendaOverviewModel`) — ejemplo REAL (verificado):**
```json
{
  "cropContext": { "cropName": "tomate", "currentStage": "floración", "currentWeek": 1 },
  "activities": [
    {
      "id": "act_1",
      "title": "Eliminar plantas afectadas",
      "description": "Eliminar plantas afectadas",
      "checklist": [],
      "scheduledDate": "2026-07-13T00:00:00.000Z",
      "weekNumber": 1,
      "status": "pending",
      "category": "tratamiento",
      "isPendingSync": false
    }
  ]
}
```
> `title`/`description` = el paso real del tratamiento (no lo redacta el LLM).
> `scheduledDate`/`weekNumber` los propone el LLM (o la regla). `category` =
> `tratamiento` | `prevencion`.

**`complete` / `postpone`** responden con el `AgendaActivityModel` actualizado (mismo
shape que un item de `activities`). `postpone` acepta body opcional `{"reason":"..."}`.

**Campos de `AgendaActivityModel`**

| Campo | Tipo | Nota |
|---|---|---|
| `id` | string | requerido |
| `title` | string | requerido |
| `description` | string | requerido |
| `scheduledDate` | string ISO-8601 | `DateTime.parse` en la app |
| `weekNumber` | int | semana del plan |
| `status` | enum string | `pending` / `completed` / `postponed` |
| `checklist` | string[] | opcional |
| `category` | enum string | opcional (`generic`, …) |
| `isPendingSync` | bool | opcional (default `false`) |

**`cropContext` (`AgendaCropContextEntity`)**

| Campo | Tipo |
|---|---|
| `cropName` | string |
| `currentStage` | string |
| `currentWeek` | int |

### 3.3 Para conectar la agenda al backend (checklist del front)
1. Fijar el baseUrl del Dio de agenda a **`http://52.1.110.21:8000/api/v1`** + **JWT Bearer**.
2. Tras `/consultar`, al pulsar "Agregar a la agenda", llamar
   **`POST /{rol}/agenda/generar`** con el `tratamiento`/`prevencion` obtenidos.
3. Usar la **ruta del rol correcto** (`/agricultor/...` o `/aprendiz/...`).
4. `GET` para mostrar la agenda; `complete` / `postpone` para actualizar actividades.

> La app puede seguir con Hive **offline**; el backend genera/persiste la agenda
> cuando hay conexión. La app ya no arma el calendario — lo hace el backend.

---

## 4. Checklist rápido para el front

- [x] **Mapa epidemiológico:** conectar YA a `GET /api/v1/clustering/mapa-campanias`
  y `GET /api/v1/alertas?estado=` en `http://52.1.110.21:8000`, con `Bearer` token.
- [x] Reusar el `Dio` de `llmBaseUrl` + `AuthInterceptor` (ya inyecta el token).
- [x] **Agenda:** backend **auto-genera por rol** en `…:8000/api/v1/{rol}/agenda`.
  Fijar baseUrl + JWT, y **llamar `POST /{rol}/agenda/generar`** tras el diagnóstico.
- [ ] (Opcional) mover los paths de clustering y agenda a `ApiEndpoints`.
