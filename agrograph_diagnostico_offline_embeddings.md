# AgroGraph — Flujo de Diagnóstico Offline (Embeddings)
### Documento técnico de arquitectura — Módulo de recomendación offline

> **Nota para implementación con Claude Code:** este documento es la especificación completa del módulo `features/offline_knowledge/`. La CNN (detección de cultivo + enfermedad) ya está implementada y NO forma parte de este alcance. Este documento cubre únicamente la generación de la explicación/recomendación detallada en modo offline, a partir del resultado que ya entrega la CNN.

---

## 0. Regla más importante del diseño

**El diagnóstico offline NO requiere ninguna llamada a API.** Todo el flujo descrito aquí ocurre 100% en el dispositivo, usando datos ya descargados previamente. La única vez que hay red involucrada es en un momento **anterior y separado**: cuando el usuario descarga el paquete de conocimiento de un cultivo (`GET /catalog/{cultivo}/offline-package`, fuera del alcance de este documento — se define después).

Una vez descargado el paquete, el ciclo completo de diagnóstico (imagen → enfermedad → explicación) funciona sin conexión, indefinidamente, hasta que el usuario decida actualizar el paquete.

```mermaid
flowchart LR
    subgraph online["🌐 Requiere red (una sola vez, previo)"]
        A[Usuario descarga<br/>paquete del cultivo]
    end
    subgraph offline["📴 100% offline (cada vez que diagnostica)"]
        B[Captura imagen] --> C[CNN detecta<br/>cultivo + enfermedad]
        C --> D[Este módulo genera<br/>la explicación detallada]
    end
    A -.paquete guardado localmente.-> D
```

---

## 1. Alcance

**Ya resuelto (fuera de este documento):**
- Captura de imagen y preprocesamiento.
- Inferencia CNN → `{cultivo, enfermedad, confianza}`.

**Lo que define este documento:**
- Cómo se transforma `{cultivo, enfermedad, confianza}` en una explicación de texto completa, offline.
- Cómo se estructura y consulta el índice local de conocimiento.
- Qué hace la app cuando no hay match confiable o no hay paquete descargado.

**Explícitamente fuera de alcance (se define en un documento posterior):**
- El endpoint `/catalog/{cultivo}/offline-package` y su contrato exacto.
- El flujo de descarga en sí (UI de progreso, manejo de errores de red al descargar).

---

## 2. Diagrama de flujo completo

```mermaid
flowchart TD
    Start(["CNN entrega resultado"]) --> R1["cultivo: 'maiz'<br/>enfermedad: 'roya_comun'<br/>confianza: 0.91"]
    R1 --> Q1{"¿Existe paquete<br/>offline descargado<br/>para 'maiz'?"}

    Q1 -- No --> N1["Mostrar solo el nombre<br/>de la enfermedad detectada"]
    N1 --> N2["CTA: 'Descarga el paquete<br/>de maíz para ver el<br/>tratamiento completo'"]

    Q1 -- Sí --> S1["Buscar ficha por ID exacto<br/>(WHERE cultivo=? AND id=?)"]
    S1 --> Q2{"¿ID existe en<br/>el paquete local?"}

    Q2 -- Sí --> M1["✅ Match exacto"]
    M1 --> Out1["DiagnosisDetail.exact()"]

    Q2 -- No --> F1["Armar texto de búsqueda<br/>a partir del ID"]
    F1 --> F2["Vectorizar con modelo<br/>de embeddings on-device"]
    F2 --> F3["Similitud coseno contra<br/>vectores del paquete local"]
    F3 --> Q3{"score >= umbral<br/>(ej. 0.55)?"}

    Q3 -- Sí --> M2["🟡 Match aproximado"]
    M2 --> Out2["DiagnosisDetail.approximate()"]

    Q3 -- No --> M3["❌ Sin resultado usable"]
    M3 --> Out3["DiagnosisDetail.notFound()"]

    Out1 --> UI["Renderizar en UI<br/>según 'source'"]
    Out2 --> UI
    Out3 --> UI
    N2 --> UI

    style M1 fill:#2D6A4F,color:#fff
    style M2 fill:#F4A261,color:#4A2800
    style M3 fill:#ADB5BD,color:#1B2D27
    style Out1 fill:#2D6A4F,color:#fff
    style Out2 fill:#F4A261,color:#4A2800
    style Out3 fill:#ADB5BD,color:#1B2D27
```

**Punto clave de diseño:** la CNN entrega un *label discreto* (no texto libre), y ese label es exactamente el mismo `id` usado en el paquete de conocimiento. Por eso el camino principal es un **lookup directo por ID** (rama izquierda del diagrama, sin vectores). El embedding solo entra en juego como *fallback*, cuando el ID no está en el paquete descargado — típicamente porque el modelo CNN se reentrenó con nuevas clases y el usuario aún no actualizó su paquete local.

---

## 3. Diagrama de secuencia — caso completo (con fallback)

```mermaid
sequenceDiagram
    actor U as Usuario
    participant P as Presentation<br/>(DiagnosisScreen)
    participant UC as UseCase<br/>(GetOfflineDiagnosisDetail)
    participant Repo as Repository<br/>(KnowledgeRepositoryImpl)
    participant SQL as Local DataSource<br/>(SQLite / sqlite-vec)
    participant EMB as Embedding Model<br/>(TFLite, on-device)

    U->>P: Toma foto de la planta
    P->>P: CNN infiere (cultivo, enfermedad, confianza)
    P->>UC: call(cultivo, enfermedadId, confianza)

    UC->>Repo: getByExactId(cultivo, enfermedadId)
    Repo->>SQL: SELECT * WHERE cultivo=? AND id=?
    SQL-->>Repo: null (no encontrado)
    Repo-->>UC: null

    Note over UC: Se activa fallback semántico

    UC->>UC: queryText = idToSearchableText(enfermedadId)
    UC->>EMB: encode(queryText)
    EMB-->>UC: vector[384]

    UC->>Repo: searchBySimilarity(cultivo, vector, topK=1)
    Repo->>SQL: consulta vectorial (coseno)
    SQL-->>Repo: [{ficha, score: 0.71}]
    Repo-->>UC: resultado

    UC-->>P: DiagnosisDetail.approximate(ficha, 0.71)
    P-->>U: Muestra ficha + banner "resultado aproximado"
```

---

## 4. Diagrama de clases — modelo de dominio

```mermaid
classDiagram
    class DiagnosisDetail {
        <<sealed>>
        +String enfermedad
        +String sintomas
        +String tratamiento
        +String severidad
        +DiagnosisSource source
        +exact(ficha, confianzaCnn) DiagnosisDetail
        +approximate(ficha, score) DiagnosisDetail
        +notFound(enfermedadId) DiagnosisDetail
    }

    class DiagnosisSource {
        <<enumeration>>
        exactMatch
        semanticFallback
        notFound
    }

    class TreatmentEntry {
        +String id
        +String cultivo
        +String enfermedad
        +String sintomas
        +String tratamiento
        +String severidad
        +List~double~ embedding
    }

    class GetOfflineDiagnosisDetailUseCase {
        +KnowledgeRepository repository
        +call(cultivo, enfermedadId, confianzaCnn) Future~DiagnosisDetail~
        -fallbackSemantico(cultivo, enfermedadId) Future~DiagnosisDetail~
    }

    class KnowledgeRepository {
        <<interface>>
        +getByExactId(cultivo, id) Future~TreatmentEntry?~
        +searchBySimilarity(cultivo, vector, topK) Future~List~ScoredEntry~~
        +hasPackageFor(cultivo) Future~bool~
    }

    class KnowledgeRepositoryImpl {
        +KnowledgeLocalDataSource localDataSource
        +getByExactId(cultivo, id) Future~TreatmentEntry?~
        +searchBySimilarity(cultivo, vector, topK) Future~List~ScoredEntry~~
    }

    class KnowledgeLocalDataSource {
        +querySQL(cultivo, id) Future~TreatmentEntry?~
        +vectorSearch(cultivo, vector, topK) Future~List~ScoredEntry~~
        +insertPackage(json) Future~void~
    }

    class EmbeddingModelDataSource {
        +encode(text) Future~List~double~~
    }

    GetOfflineDiagnosisDetailUseCase --> KnowledgeRepository
    GetOfflineDiagnosisDetailUseCase --> EmbeddingModelDataSource
    KnowledgeRepositoryImpl ..|> KnowledgeRepository
    KnowledgeRepositoryImpl --> KnowledgeLocalDataSource
    DiagnosisDetail --> DiagnosisSource
    TreatmentEntry <-- KnowledgeLocalDataSource
```

---

## 5. Diagrama de estados — `DiagnosisSource` y su efecto en UI

```mermaid
stateDiagram-v2
    [*] --> SinPaquete: CNN detecta enfermedad
    SinPaquete --> MostrarCTA: no hay paquete del cultivo

    [*] --> BuscandoExacto: hay paquete descargado
    BuscandoExacto --> ExactMatch: ID encontrado
    BuscandoExacto --> BuscandoSemantico: ID no encontrado

    BuscandoSemantico --> SemanticFallback: score >= 0.55
    BuscandoSemantico --> NotFound: score < 0.55

    ExactMatch --> [*]: UI normal, sin advertencia
    SemanticFallback --> [*]: UI con banner amber\n+ CTA actualizar paquete
    NotFound --> [*]: UI gris\n"disponible al sincronizar"
    MostrarCTA --> [*]: UI gris\nCTA descargar paquete
```

---

## 6. Caso principal — Match exacto por ID (95%+ de los casos esperados)

Como el label de salida de la CNN es fijo (viene del set de clases con el que se entrenó el modelo) y el `id` de cada ficha del paquete JSON se genera con la misma nomenclatura, la búsqueda es una consulta directa, sin vectores:

```dart
// domain/usecases/get_offline_diagnosis_detail_usecase.dart
class GetOfflineDiagnosisDetailUseCase {
  final KnowledgeRepository repository;
  final EmbeddingModelDataSource embeddingModel;

  GetOfflineDiagnosisDetailUseCase(this.repository, this.embeddingModel);

  Future<DiagnosisDetail> call({
    required String cultivo,
    required String enfermedadId,   // viene directo de la CNN
    required double confianzaCnn,
  }) async {
    final tienePaquete = await repository.hasPackageFor(cultivo);
    if (!tienePaquete) {
      return DiagnosisDetail.packageMissing(cultivo);
    }

    final ficha = await repository.getByExactId(cultivo, enfermedadId);
    if (ficha != null) {
      return DiagnosisDetail.exact(ficha, confianzaCnn);
    }

    // No está en el paquete local → fallback semántico
    return _fallbackSemantico(cultivo, enfermedadId);
  }

  Future<DiagnosisDetail> _fallbackSemantico(String cultivo, String enfermedadId) async {
    final queryText = _idToSearchableText(enfermedadId, cultivo);
    final queryVector = await embeddingModel.encode(queryText);

    final resultados = await repository.searchBySimilarity(
      cultivo: cultivo,
      queryVector: queryVector,
      topK: 1,
    );

    if (resultados.isEmpty || resultados.first.score < 0.55) {
      return DiagnosisDetail.notFound(enfermedadId);
    }

    return DiagnosisDetail.approximate(resultados.first.ficha, resultados.first.score);
  }

  String _idToSearchableText(String id, String cultivo) {
    // ej. "roya_comun" + "maiz" → "roya común maíz"
    return '${id.replaceAll('_', ' ')} $cultivo';
  }
}
```

No requiere vectorizar nada en el camino principal — es una consulta SQL simple contra la tabla local donde se guardó el paquete descargado.

---

## 7. Estructura de respuesta — `DiagnosisDetail`

```dart
// domain/entities/diagnosis_detail.dart
sealed class DiagnosisDetail {
  final String enfermedad;
  final String sintomas;
  final String tratamiento;
  final String severidad;
  final DiagnosisSource source;

  const DiagnosisDetail({
    required this.enfermedad,
    required this.sintomas,
    required this.tratamiento,
    required this.severidad,
    required this.source,
  });

  factory DiagnosisDetail.exact(TreatmentEntry ficha, double confianzaCnn) => _Exact(ficha, confianzaCnn);
  factory DiagnosisDetail.approximate(TreatmentEntry ficha, double score) => _Approximate(ficha, score);
  factory DiagnosisDetail.notFound(String enfermedadId) => _NotFound(enfermedadId);
  factory DiagnosisDetail.packageMissing(String cultivo) => _PackageMissing(cultivo);
}

enum DiagnosisSource { exactMatch, semanticFallback, notFound, packageMissing }
```

### 7.1 Qué muestra la UI según el `source`

| `source` | Texto mostrado | Tono visual |
|---|---|---|
| `exactMatch` | Ficha completa, sin advertencia | Normal, igual que respuesta online |
| `semanticFallback` | Ficha + banner: *"Resultado aproximado — actualiza el paquete de [cultivo] para mayor precisión"* | Amber `#F4A261`, con botón "Actualizar ahora" |
| `notFound` | *"No se encontró información offline para esta enfermedad. Se mostrará al recuperar conexión."* | Gris `#ADB5BD`, mismo patrón del banner offline global |
| `packageMissing` | Solo nombre de enfermedad + *"Descarga el paquete de [cultivo] para ver el tratamiento completo"* | Gris `#ADB5BD` + CTA de descarga |

Reutiliza el mismo lenguaje visual ya definido para el banner offline global (ícono wifi-off) y el sistema de colores de estado de salud (`#E76F51` alerta, `#F4A261` seguimiento, `#2D6A4F` saludable).

---

## 8. Contrato de datos del paquete local (recordatorio — el endpoint se define después)

El paquete descargado es la única fuente de verdad offline. Estructura relevante para este flujo:

```json
{
  "cultivo": "maiz",
  "version": "2026.07.11",
  "embedding_model": "paraphrase-multilingual-MiniLM-L12-v2",
  "embedding_dim": 384,
  "fichas": [
    {
      "id": "roya_comun",
      "enfermedad": "Roya común",
      "sintomas": "Pústulas de color naranja-café en el envés de las hojas...",
      "tratamiento": "Aplicar fungicida triazol cada 10-14 días...",
      "severidad": "media",
      "embedding": [0.0123, -0.045]
    }
  ]
}
```

**Importante:** el campo `id` de cada ficha debe estar sincronizado 1:1 con las clases de salida del modelo CNN. Cualquier reentrenamiento que agregue/quite clases debe disparar una regeneración del paquete offline.

---

## 9. Estructura de carpetas (Clean Architecture)

```mermaid
graph TD
    subgraph feature["features/offline_knowledge/"]
        subgraph domain["domain/"]
            D1["entities/<br/>diagnosis_detail.dart<br/>treatment_entry.dart"]
            D2["usecases/<br/>get_offline_diagnosis_detail_usecase.dart"]
            D3["repositories/<br/>knowledge_repository.dart (interface)"]
        end
        subgraph data["data/"]
            DA1["datasources/<br/>knowledge_local_datasource.dart<br/>embedding_model_datasource.dart"]
            DA2["repositories/<br/>knowledge_repository_impl.dart"]
        end
        subgraph presentation["presentation/"]
            P1["widgets/<br/>diagnosis_detail_view.dart<br/>package_missing_banner.dart<br/>approximate_match_banner.dart"]
        end
    end

    P1 --> D2
    D2 --> D3
    D2 --> DA1
    DA2 -.implementa.-> D3
    DA2 --> DA1
```

| Capa | Responsabilidad en este flujo |
|---|---|
| `domain/usecases/` | `GetOfflineDiagnosisDetailUseCase` — orquesta match exacto → fallback semántico → not found |
| `domain/entities/` | `DiagnosisDetail`, `TreatmentEntry` |
| `data/datasources/` | `KnowledgeLocalDataSource` (consulta SQL exacta + búsqueda vectorial), `EmbeddingModelDataSource` (wrapper TFLite) |
| `data/repositories/` | `KnowledgeRepositoryImpl` — implementa `getByExactId` y `searchBySimilarity` |
| `presentation/` | Renderiza `DiagnosisDetail` según `source`, muestra banners de advertencia/CTA |

**Nota:** este feature **no toca `core/network/`** — no hay `ApiClient` involucrado en ningún punto de este flujo. Eso confirma la regla de la sección 0: cero dependencia de red para mostrar resultados offline.

---

## 10. Casos límite a contemplar

- **Paquete parcialmente corrupto o descarga interrumpida:** validar `fichas.length > 0` antes de indexar; si falla, tratar como `packageMissing`.
- **Cultivo detectado pero nunca descargado:** estado `packageMissing`, ya cubierto en el diagrama de estados.
- **Confianza baja de la CNN:** este documento asume que la CNN ya filtra esto antes de invocar el use case; si no es así, debe añadirse esa validación antes del paso 1.
- **Múltiples versiones de paquete en dispositivo:** al descargar una nueva versión, se reemplaza completamente el índice anterior de ese cultivo (no se mezclan versiones distintas del `embedding_model`).

---

## 11. Pendiente de definir (documentos posteriores)

- Contrato exacto del endpoint `GET /catalog/{cultivo}/offline-package`.
- Flujo de descarga (UI, manejo de error de red, progreso).
- Calibración real del umbral de similitud (`0.55` es un valor de arranque, no validado con datos).
- Política de expiración/recordatorio de actualización de paquetes.
- Tamaño máximo de almacenamiento local permitido por cultivos descargados simultáneamente.
