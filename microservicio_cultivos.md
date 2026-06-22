# Microservicio de Cultivos — AgroGraph-MAS

## 1. Arquitectura

### Responsabilidades

El microservicio de cultivos es la fuente de verdad para:

- Catálogo de cultivos disponibles en la app
- Metadata agrícola enriquecida para inferencia IA
- Distribución de modelos CNN y embeddings LLM
- Sincronización offline incremental hacia el cliente Flutter

### Stack recomendado

| Capa | Tecnología |
|------|-----------|
| Runtime | Node.js (Fastify) o Python (FastAPI) |
| Base de datos | PostgreSQL |
| Caché | Redis |
| Almacenamiento de modelos | S3-compatible (MinIO en self-hosted) |
| Auth | JWT + API Keys por cliente |

### Flujo general

```
Cliente Flutter
  │
  ├─ Online  → REST API → PostgreSQL + Redis (caché metadata)
  │                     → S3 (modelos CNN, embeddings)
  │
  └─ Offline → Hive/Isar local → motor de inferencia local
                               → cola de sync pendiente
```

---

## 2. Modelo de datos — Cultivo

```json
{
  "id": "uuid-v4",
  "nombre": "Maíz",
  "slug": "maiz",
  "categoria": "cereal",
  "descripcion": "Cultivo básico de ciclo corto, ampliamente distribuido en México.",
  "imagen_url": "https://cdn.agrograph.app/cultivos/maiz.webp",
  "icono_url": "https://cdn.agrograph.app/cultivos/icons/maiz.svg",
  "region_recomendada": ["Chiapas", "Oaxaca", "Veracruz", "Puebla"],
  "tipo_terreno_compatible": ["Plano", "Pendiente ligera"],
  "condiciones_suelo": ["Húmedo", "Bien drenado", "Arcilloso"],
  "malezas_comunes": ["Hoja ancha", "Pastos", "Mixta"],
  "temperatura_min": 10,
  "temperatura_max": 35,
  "humedad_ideal": "media-alta",
  "temporada_siembra": "Marzo–Mayo",
  "temporada_cosecha": "Agosto–Octubre",
  "tipo_suelo": "franco-arcilloso",
  "nivel_riego": "medio",
  "estado": "activo",
  "cnn_model_version": "v2.1.0",
  "llm_context_version": "v1.3.0",
  "top_k_version": "v1.0.0",
  "offline_enabled": true,
  "sync_version": "2024-11-01T00:00:00Z",
  "checksum": "sha256:abc123...",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-11-01T00:00:00Z"
}
```

### Catálogo inicial (15 cultivos MVP)

`Calabaza`, `Frijol`, `Manzana`, `Mora`, `Cereza`, `Maíz`, `Durazno`, `Uva`, `Naranja`, `Pimienta`, `Papa`, `Frambuesa`, `Soja`, `Fresa`, `Tomate`

---

## 3. Endpoints CRUD

### Base URL
```
/api/v1/cultivos
```

### Obtener todos los cultivos
```
GET /api/v1/cultivos
```
Query params opcionales: `categoria`, `region`, `estado`, `offline_enabled`

Respuesta:
```json
{
  "data": [ /* array de cultivos */ ],
  "sync_version": "2024-11-01T00:00:00Z",
  "total": 15
}
```

### Obtener cultivo por ID
```
GET /api/v1/cultivos/:id
GET /api/v1/cultivos/slug/:slug
```

### Crear cultivo (admin)
```
POST /api/v1/cultivos
Authorization: Bearer <admin-token>
```

### Actualizar cultivo (admin)
```
PATCH /api/v1/cultivos/:id
Authorization: Bearer <admin-token>
```

### Eliminar cultivo (admin)
```
DELETE /api/v1/cultivos/:id
Authorization: Bearer <admin-token>
```

---

## 4. Endpoints IA

### Metadata IA por cultivo
```
GET /api/v1/cultivos/:id/ia-metadata
```
Respuesta:
```json
{
  "cultivo_id": "uuid",
  "llm_context": "El maíz (Zea mays) es un cereal C4 con alta demanda de nitrógeno...",
  "prompt_agricola_base": "Eres un agrónomo experto en cultivos de Chiapas...",
  "disease_classes": ["tizón foliar", "roya común", "pudrición de raíz"],
  "confidence_threshold": 0.72,
  "embeddings_available": true,
  "top_k_disponible": true,
  "cnn_model_version": "v2.1.0"
}
```

### Descargar embeddings
```
GET /api/v1/cultivos/:id/embeddings
Accept: application/octet-stream
```
Retorna archivo `.bin` compatible con inferencia local (ONNX / TFLite).

### Descargar top-k vectores
```
GET /api/v1/cultivos/:id/top-k
```
Retorna JSON con los K vectores más relevantes para inferencia RAG offline.

### Descargar modelo CNN
```
GET /api/v1/cultivos/:id/cnn-model
Accept: application/octet-stream
```
Retorna modelo `.tflite` listo para ejecutarse en Flutter (tflite_flutter).

### Labels de enfermedades
```
GET /api/v1/cultivos/:id/disease-labels
```
```json
{
  "cultivo_id": "uuid",
  "labels": [
    { "id": 0, "nombre": "Sano", "severity": "none" },
    { "id": 1, "nombre": "Tizón foliar", "severity": "medium" },
    { "id": 2, "nombre": "Roya común", "severity": "high" }
  ],
  "model_version": "v2.1.0"
}
```

### Prompts agrícolas
```
GET /api/v1/cultivos/:id/prompts
```
```json
{
  "system_prompt": "Eres un agrónomo especializado en...",
  "context_variables": ["region", "tipo_terreno", "condicion_suelo", "malezas"],
  "version": "v1.3.0"
}
```

---

## 5. Endpoints Offline / Sincronización

### Sincronización incremental
```
GET /api/v1/sync/cultivos?since=<ISO8601>&version=<local_version>
```
Retorna solo los registros modificados desde `since`.

```json
{
  "updated": [ /* cultivos modificados */ ],
  "deleted_ids": ["uuid-1", "uuid-2"],
  "server_time": "2024-11-15T12:00:00Z",
  "next_sync_token": "eyJ..."
}
```

### Descarga parcial (por región)
```
GET /api/v1/sync/cultivos/region/:region_slug
```
Descarga solo los cultivos relevantes para una región.

### Verificación de checksum
```
POST /api/v1/sync/verify
Content-Type: application/json

{
  "items": [
    { "id": "uuid-1", "checksum": "sha256:abc..." },
    { "id": "uuid-2", "checksum": "sha256:xyz..." }
  ]
}
```
Respuesta: lista de IDs que requieren re-descarga.

### Estado de versiones de modelos IA
```
GET /api/v1/sync/ia-versions
```
```json
{
  "cultivos": {
    "maiz":    { "cnn": "v2.1.0", "embeddings": "v1.0.0", "prompts": "v1.3.0" },
    "tomate":  { "cnn": "v1.8.0", "embeddings": "v1.0.0", "prompts": "v1.3.0" }
  },
  "updated_at": "2024-11-01T00:00:00Z"
}
```

---

## 6. Compatibilidad CNN

### Especificación del modelo
```json
{
  "framework": "TensorFlow Lite",
  "input_shape": [1, 224, 224, 3],
  "input_dtype": "float32",
  "normalization": "0–1",
  "output_shape": [1, N],
  "confidence_threshold": 0.72,
  "model_version": "v2.1.0",
  "disease_classes": [
    "Sano",
    "Tizón foliar",
    "Roya común",
    "Pudrición de raíz"
  ]
}
```

### Variables de contexto para CNN + IA
| Variable | Fuente | Uso |
|----------|--------|-----|
| `cultivo` | Selección usuario | Selecciona modelo CNN correcto |
| `region` | Campo manual | Ajusta umbrales regionales |
| `tipo_terreno` | Acordeón | Contexto agronómico LLM |
| `condicion_suelo` | Acordeón | Filtro de enfermedades compatibles |
| `malezas` | Acordeón | Contexto de inferencia |
| `fecha_siembra` | Campo fecha | Etapa fenológica estimada |

---

## 7. Compatibilidad LLM

### Contexto agrícola enriquecido por parcela

El cliente Flutter construye este payload antes de llamar al LLM:

```json
{
  "cultivo": "Maíz",
  "region": "Ocosingo, Chiapas",
  "tipo_terreno": "Pendiente ligera",
  "condicion_suelo": ["Húmedo", "Arcilloso"],
  "malezas": ["Pastos", "Hoja ancha"],
  "etapa_fenologica": "Vegetativa",
  "dias_desde_siembra": 38,
  "diagnostico_cnn": {
    "clase": "Tizón foliar",
    "confianza": 0.89
  }
}
```

### Prompt base (servidor provee, cliente cachea)
```
Eres un agrónomo experto en cultivos de {region}.
El agricultor tiene una parcela de {cultivo} en etapa {etapa_fenologica}.
Terreno: {tipo_terreno}. Suelo: {condicion_suelo}. Malezas: {malezas}.
El diagnóstico visual indica: {diagnostico_cnn.clase} con {diagnostico_cnn.confianza*100}% de confianza.
Proporciona recomendaciones claras, prácticas y sin tecnicismos innecesarios.
```

---

## 8. Estrategia Offline

### Almacenamiento local (Flutter)

| Tipo de dato | Motor | Justificación |
|---|---|---|
| Metadata cultivos | **Hive** (ya en pubspec) | Rápido, sin SQL, serializable |
| Modelos CNN | Filesystem local (path_provider) | Binarios grandes |
| Embeddings / top-k | Hive (bytes) | Acceso O(1) por cultivo |
| Prompts LLM | Hive (strings) | Actualizables sin modelo nuevo |
| Cola de sync | Hive + timestamp | Merge en reconexión |

### Flujo offline completo

```
App arranca
  │
  ├─ Online → Verificar versiones (/api/v1/sync/ia-versions)
  │          → Descargar solo deltas (sincronización incremental)
  │          → Guardar en Hive + filesystem
  │
  └─ Offline → Cargar metadata desde Hive
             → Ejecutar CNN con modelo local (.tflite)
             → Consultar top-k local para RAG
             → Generar respuesta LLM con modelo local o prompt fallback
             → Guardar diagnóstico en cola sync local
             → Cuando vuelva internet: sync cola al servidor
```

### Política de invalidación de caché
- Versión en checksum SHA-256 por cultivo
- Invalidar si `sync_version` del servidor > versión local
- Límite de almacenamiento: 150 MB total por app
- Prioridad de descarga: cultivo seleccionado por el usuario primero

### Resolución de conflictos offline/online
- Regla: **servidor gana** para metadata de cultivos
- Regla: **cliente gana** para datos de parcelas del usuario
- Timestamps ISO 8601 para ordenaición correcta

---

## 9. Seguridad

### Autenticación
- Endpoints públicos de catálogo: API Key en header `X-API-Key`
- Endpoints de admin (CRUD): JWT Bearer + rol `admin`
- Endpoints de sync cliente: JWT de sesión del agricultor

### Rate Limiting
| Endpoint | Límite |
|---|---|
| GET cultivos / catálogo | 200 req/min por IP |
| GET CNN model / embeddings | 10 req/min por usuario |
| POST sync/verify | 30 req/min por usuario |
| POST admin | 20 req/min por IP |

### Validaciones
- Sanitización de todos los inputs
- Tamaño máximo de payload: 10 MB (sync), 1 MB (metadata)
- CORS restringido a dominios de la app
- HTTPS obligatorio en producción

### Versionado de API
- Header: `Accept: application/vnd.agrograph.v1+json`
- URL: `/api/v1/`, `/api/v2/`
- Deprecación con 90 días de aviso + header `Sunset`

---

## 10. Resultado esperado del microservicio

Al tener este microservicio operativo, la app podrá:

1. **Mostrar catálogo visual** de 15 cultivos con imagen/icono desde CDN
2. **Inferir enfermedades sin internet** usando modelos CNN descargados
3. **Generar recomendaciones** usando prompts + contexto agrícola del usuario
4. **Sincronizar progresivamente** solo los deltas cuando recupere conexión
5. **Personalizar diagnósticos** según región, suelo, terreno y malezas del agricultor
6. **Escalar** agregando nuevos cultivos sin actualizar la app (hot-update de metadata)
