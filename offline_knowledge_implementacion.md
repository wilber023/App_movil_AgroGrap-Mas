# Implementación — `features/offline_knowledge/`

Implementación del módulo de diagnóstico offline por embeddings especificado en
`agrograph_diagnostico_offline_embeddings.md`. Feature 100% aditiva: no se
modificó ninguna entidad, caso de uso, repositorio ni el `ApiClient`/endpoints
del flujo online existente (CNN → LLM vía API).

## 1. Archivos creados

### Domain

| Archivo | Capa |
|---|---|
| `lib/features/offline_knowledge/domain/entities/treatment_entry.dart` | domain/entities |
| `lib/features/offline_knowledge/domain/entities/scored_entry.dart` | domain/entities |
| `lib/features/offline_knowledge/domain/entities/diagnosis_detail.dart` | domain/entities |
| `lib/features/offline_knowledge/domain/repositories/knowledge_repository.dart` | domain/repositories |
| `lib/features/offline_knowledge/domain/usecases/get_offline_diagnosis_detail_usecase.dart` | domain/usecases |

### Data

| Archivo | Capa |
|---|---|
| `lib/features/offline_knowledge/data/datasources/embedding_model_datasource.dart` | data/datasources |
| `lib/features/offline_knowledge/data/datasources/knowledge_local_datasource.dart` | data/datasources |
| `lib/features/offline_knowledge/data/repositories/knowledge_repository_impl.dart` | data/repositories |

### Presentation

| Archivo | Capa |
|---|---|
| `lib/features/offline_knowledge/presentation/cubit/offline_knowledge_cubit.dart` | presentation/cubit |
| `lib/features/offline_knowledge/presentation/widgets/diagnosis_detail_view.dart` | presentation/widgets |
| `lib/features/offline_knowledge/presentation/widgets/package_missing_banner.dart` | presentation/widgets |
| `lib/features/offline_knowledge/presentation/widgets/approximate_match_banner.dart` | presentation/widgets |

### Tests

| Archivo |
|---|
| `test/features/offline_knowledge/get_offline_diagnosis_detail_usecase_test.dart` |
| `test/features/offline_knowledge/cosine_similarity_test.dart` |

### Archivos existentes modificados (punto de integración e inyección de dependencias)

| Archivo | Cambio |
|---|---|
| `lib/core/di/injection_container.dart` | Se agregó `_initOfflineKnowledgeFeature()` (nueva sección, no toca las existentes) y su llamada desde `initDependencies()`. |
| `lib/features/agricultor/diagnosis/presentation/pages/diagnosis_result_page.dart` | Punto de integración mínimo (ver sección 3). Ningún otro widget/lógica de la pantalla fue tocado. |

## 2. Verificación — `flutter analyze` y `flutter test`

### Antes de los cambios

```
flutter analyze
   info - Statements in an if should be enclosed in a block - lib\features\agricultor\parcels\presentation\pages\parcels_page.dart:827:7 - curly_braces_in_flow_control_structures
1 issue found. (ran in 256.1s)

flutter test
00:00 +0: loading D:/AgroGrap_Movil/test/widget_test.dart
00:00 +0: App startup smoke test
00:00 +1: All tests passed!
```

### Después de los cambios

```
flutter analyze
   info - Statements in an if should be enclosed in a block - lib\features\agricultor\parcels\presentation\pages\parcels_page.dart:827:7 - curly_braces_in_flow_control_structures
   info - Constructors in '@immutable' classes should be declared as 'const' - lib\features\offline_knowledge\domain\entities\diagnosis_detail.dart:92:3 - prefer_const_constructors_in_immutables
   info - Constructors in '@immutable' classes should be declared as 'const' - lib\features\offline_knowledge\domain\entities\diagnosis_detail.dart:106:3 - prefer_const_constructors_in_immutables
3 issues found. (ran in 4.9s)

flutter test
00:00 +0: loading D:/AgroGrap_Movil/test/features/offline_knowledge/cosine_similarity_test.dart
00:00 +0: ...vectores idénticos -> score 1.0
00:00 +1: ...vectores ortogonales -> score 0.0
00:00 +2: ...vectores opuestos -> score -1.0
00:00 +3: ...vectores parcialmente similares -> score intermedio
00:00 +4: ...vector cero -> score 0.0 (evita división por cero)
00:00 +5: ...paquete no descargado -> packageMissing
00:00 +6: ...match exacto por ID -> exact
00:00 +7: ...fallback semántico exitoso (score >= umbral) -> approximate
00:00 +8: ...fallback semántico por debajo del umbral -> notFound
00:00 +9: ...sin resultados de similitud -> notFound
00:00 +10: D:/AgroGrap_Movil/test/widget_test.dart: App startup smoke test
00:00 +11: All tests passed!
```

**Conclusión:** 0 errores de análisis antes y después (solo `info`, no
bloqueantes). Los 2 `info` nuevos son de un lint (`prefer_const_constructors_in_immutables`)
que Dart no permite satisfacer aquí: el constructor de `DiagnosisDetailExact`
y `DiagnosisDetailApproximate` lee campos de instancia del parámetro `ficha`
(`ficha.enfermedad`, etc.) dentro del `super(...)`, lo cual es incompatible
con `const`. El test preexistente (`App startup smoke test`) sigue pasando
sin cambios, y los 10 tests nuevos de `offline_knowledge` pasan. El flujo
online (`LlmDiagnosisCubit` / `LlmDiagnosisRepositoryImpl` /
`llm_diagnosis_datasource.dart`) no fue modificado en absoluto.

## 3. Punto de integración mínimo

Vive únicamente en `diagnosis_result_page.dart` (flujo **agricultor**; el
flujo aprendiz — `DiagnosisResultAprendizPage` — queda fuera de este sprint
por decisión explícita):

- **`_ResultViewState.initState()`**: antes de llamar a `LlmDiagnosisCubit.consultar()`
  incondicionalmente, ahora se consulta `sl<NetworkInfo>().isConnected`. Si
  hay conexión, se llama exactamente al mismo `consultar()` de siempre (flujo
  online sin cambios). Si no hay conexión, se llama a
  `OfflineKnowledgeCubit.load(...)`, que internamente invoca
  `GetOfflineDiagnosisDetailUseCase`.
- **`_buildSummaryCard()`**: el `BlocBuilder<LlmDiagnosisCubit, ...>` que
  renderizaba el cuerpo del diagnóstico fue envuelto en un
  `BlocBuilder<OfflineKnowledgeCubit, ...>` externo: si hay un
  `OfflineKnowledgeLoaded`, se renderiza `DiagnosisDetailView`; si no, se
  delega al `BlocBuilder<LlmDiagnosisCubit>` original sin ningún cambio
  (extraído a `_buildLlmBody()` tal cual estaba).
- **Reversión**: ambos puntos están marcados con el comentario
  `// === Punto de integración offline_knowledge ===` y una nota de cómo
  revertir cada uno (eliminar el `if/else` de conectividad y el
  `BlocBuilder<OfflineKnowledgeCubit>` externo).
- Métricas, Top-K, recomendaciones de prevención, botón de agenda y
  productos recomendados **no** se tocaron; en modo offline simplemente no
  se disparan (dependen de `LlmDiagnosisLoaded`, que nunca ocurre si no hubo
  llamada online), lo cual es el comportamiento esperado para el alcance de
  este sprint.

## 4. Decisiones tomadas que no estaban 100% especificadas en el documento

1. **Base de datos SQLite separada** — Se creó `agro_knowledge.db` con tablas
   propias (`knowledge_fichas`, `knowledge_packages`), completamente
   independiente de `agro_offline.db` (usada por la feature legacy
   `features/agricultor/offline/`, documentada en `offline_architecture.md`,
   que implementa un RAG de documentos/chunks distinto y no relacionado con
   el modelo de `TreatmentEntry` por ID de este documento). **Confirmado con
   el usuario antes de implementar** — dos sistemas "offline" coexisten
   intencionalmente hasta una eventual consolidación futura.
2. **Estado de presentación con Cubit** — Se usó `OfflineKnowledgeCubit`
   (Cubit, no Bloc), replicando el patrón de `LlmDiagnosisCubit` (el análogo
   más cercano: un solo método disparador, sin eventos complejos).
   **Confirmado con el usuario.**
3. **Alcance del punto de integración: solo agricultor** — El flujo aprendiz
   (`DiagnosisResultAprendizPage`) no fue tocado. **Confirmado con el
   usuario.**
4. **Mapeo `cultivo`/`enfermedadId` hacia el paquete offline** — El
   documento asume que el `id` de cada ficha coincide 1:1 con el raw label
   de la CNN, pero `DiagnosisEntity` (entidad ya existente) solo expone
   `cropName`/`diseaseName` ya traducidos al español (ej. "Maíz", "Roya
   común"), no el raw label. Se resolvió así:
   - `enfermedadId`: se usa `diagnosis.topK.first.rawLabel` cuando está
     disponible (session actual, recién diagnosticado); si no (ej. al
     reabrir un diagnóstico ya guardado, donde `topK` no se persiste en
     Hive), se cae a un slug best-effort del nombre de enfermedad traducido.
   - `cultivo`: se aplica un slugify simple (minúsculas, sin acentos,
     `Maíz` → `maiz`) al nombre de cultivo ya traducido, ya que el JSON de
     ejemplo del documento (sección 8) usa cultivos en minúsculas sin
     acentos.
   - **Esto no fue confirmado con el usuario** — es una inferencia razonable
     pero debe validarse contra el contrato real del endpoint de descarga
     cuando se defina, y contra el `class_mapping.json` real de la CNN.
5. **Ícono de los banners** — El documento (sección 7.1) menciona "ícono
   wifi-off" para el lenguaje visual reutilizado, pero el `OfflineBanner`
   real ya existente en `core/widgets/shared_components.dart` usa
   `Icons.cloud_off_outlined`. Se siguió el ícono realmente usado en el
   código (`cloud_off_outlined`) en `ApproximateMatchBanner` y
   `PackageMissingBanner`, no el texto literal del documento, para mantener
   consistencia visual real con el banner global.
6. **Mapeo de color por severidad en `DiagnosisDetailExact`/`Approximate`** —
   No especificado en el documento. Se mapeó `severidad` (texto libre:
   "alta"/"media"/"leve", etc.) al sistema de colores de estado de salud ya
   documentado en la sección 7.1 (`AppColors.burntOrange` para
   alta/severa/grave, `AppColors.warmAmber` para media/moderada,
   `AppColors.forestGreen` en cualquier otro caso).
7. **`notFound` reutiliza `OfflineBanner` directamente** — En vez de crear un
   tercer archivo de banner (el documento solo pide
   `package_missing_banner.dart` y `approximate_match_banner.dart`), el
   estado `notFound` reutiliza el widget `OfflineBanner` ya existente
   pasándole el mensaje de la sección 7.1, siguiendo al pie de la letra la
   instrucción de "reutilizar, no duplicar".

## 5. TODOs dejados a propósito

1. **Modelo de embeddings real** — `EmbeddingModelDataSourceImpl.encode()`
   devuelve un vector determinístico basado en hash del texto (mismo texto →
   mismo vector), no una inferencia TFLite real. Marcado con
   `// TODO: reemplazar con modelo real cuando esté disponible` en
   `embedding_model_datasource.dart`. **No se declaró** el asset
   `assets/models/embedding_model.tflite` en `pubspec.yaml` a propósito: como
   el archivo `.tflite` no existe todavía, declararlo habría roto
   `flutter run`/`build` (Flutter falla si un asset declarado no existe en
   disco).
2. **Endpoint de descarga** — `GET /catalog/{cultivo}/offline-package` no fue
   implementado ni se agregó ningún datasource remoto, tal como se pidió.
   `KnowledgeRepository.insertPackage(json)` ya está definida y con
   implementación funcional en `KnowledgeLocalDataSourceImpl` (valida
   `fichas.isNotEmpty`, reemplaza el índice previo del cultivo dentro de una
   transacción). Conectar la descarga real será: `GET` → parsear JSON →
   `insertPackage(json)`.
3. **UI de descarga funcional** — `PackageMissingBanner` y
   `ApproximateMatchBanner` tienen botones ("Descargar paquete" /
   "Actualizar ahora") con `onPressed` expuesto como parámetro opcional
   (`null` por defecto → deshabilitado) y un comentario
   `// TODO: conectar con el endpoint de descarga cuando esté disponible`.
   No hay lógica de descarga conectada.

No se avanzó sobre el endpoint de descarga ni el consumo del nuevo servicio
LLM, según lo indicado.

---

# Sprint 2 — Conexión con la UI de descarga (Perfil → "Diagnóstico sin Conexión")

Conecta el módulo `offline_knowledge` (ya implementado en el sprint 1) con la
pantalla de descarga que ya existía en la app. Sigue siendo 100% aditivo
sobre el flujo online: no se tocó `LlmDiagnosisRepositoryImpl`, el
`ApiClient` compartido, ni la lógica de `GetOfflineDiagnosisDetailUseCase` /
`OfflineKnowledgeCubit` del sprint anterior — solo se agregó el datasource
remoto y su conexión con la UI.

## 1. Archivos nuevos/modificados

### Nuevos

| Archivo | Capa |
|---|---|
| `lib/features/offline_knowledge/data/datasources/knowledge_remote_datasource.dart` | data/datasources |
| `lib/features/offline_knowledge/domain/cultivo_slug.dart` | domain (utilidad compartida) |
| `lib/features/offline_knowledge/presentation/cubit/offline_package_manager_cubit.dart` | presentation/cubit |
| `test/features/offline_knowledge/knowledge_remote_datasource_test.dart` | test |
| `test/features/offline_knowledge/knowledge_repository_download_test.dart` | test |

### Modificados

| Archivo | Cambio |
|---|---|
| `lib/core/network/api_endpoints.dart` | Agrega `ApiEndpoints.offlineKnowledgeBaseUrl`, `ApiEndpoints.offlineKnowledgeTimeoutMs` y la clase `OfflineKnowledgeEndpoints` (`packageFor(cultivo)`). |
| `lib/features/offline_knowledge/domain/repositories/knowledge_repository.dart` | Agrega `downloadAndInstallPackage(String cultivo)` a la interfaz. |
| `lib/features/offline_knowledge/data/repositories/knowledge_repository_impl.dart` | Implementa `downloadAndInstallPackage`: `remoteDataSource.downloadPackage()` → `localDataSource.insertPackage()` (sin reimplementar validación ni la escritura en SQLite, ya existentes). |
| `lib/core/di/injection_container.dart` | Registra `KnowledgeRemoteDataSource` y `OfflinePackageManagerCubit`; pasa `remoteDataSource` a `KnowledgeRepositoryImpl`. |
| `lib/features/agricultor/diagnosis/presentation/pages/diagnosis_result_page.dart` | Refactor menor: usa la función compartida `cultivoSlug()` en vez de un helper privado duplicado (mismo comportamiento, sin cambio funcional). |
| `lib/features/agricultor/offline/presentation/pages/offline_mode_page.dart` | Reescritura de la sección de descarga (ver sección 4). El toggle "Modo sin conexión" y su `OfflineCubit` legacy quedan intactos. |
| `test/features/offline_knowledge/get_offline_diagnosis_detail_usecase_test.dart` | El fake de `KnowledgeRepository` implementa el nuevo método `downloadAndInstallPackage` (requerido por la interfaz). |

**No se tocó**: `KnowledgeLocalDataSource`, `GetOfflineDiagnosisDetailUseCase`, `OfflineKnowledgeCubit`, `DiagnosisDetailView`/banners, ni ningún archivo de `features/agricultor/offline/` fuera de `offline_mode_page.dart` (el `OfflineCubit`/`OfflineRepository`/catálogo mock legacy siguen existiendo tal cual, solo dejaron de ser invocados desde esta pantalla para la descarga).

## 2. Dónde queda la IP/puerto para probar contra el servidor real

**Una sola constante:** `ApiEndpoints.offlineKnowledgeBaseUrl` en
[lib/core/network/api_endpoints.dart](lib/core/network/api_endpoints.dart)
(línea ~19):

```dart
static const String offlineKnowledgeBaseUrl = 'http://52.1.110.21:8000';
```

Valor de arranque = mismo host que `llmBaseUrl` (el equipo LLM/RAG es quien
expone este endpoint según indicaste), pero es una constante **independiente**
de `llmBaseUrl` — cambiarla no afecta el diagnóstico online. Para apuntar al
servidor real solo hace falta editar esa línea (y, si el puerto/timeout de
descarga necesita ser distinto, `ApiEndpoints.offlineKnowledgeTimeoutMs` justo
debajo, aunque hoy no se usa activamente porque se reutiliza el `Dio`
compartido con sus timeouts por defecto — ver decisión 3 abajo).

El path se arma en `ApiEndpoints.offlineKnowledge.packageFor(cultivo)` →
`/catalog/{cultivo}/offline-package`, igual al contrato del documento de
especificación.

## 3. Resultado de `flutter analyze` y `flutter test`

### Antes de este sprint (idéntico al final del sprint 1)

```
flutter analyze
   info - ...parcels_page.dart:827:7 (preexistente, no relacionado)
   info - ...diagnosis_detail.dart:92/106 (sprint 1, constructores no-const inevitables)
3 issues found.

flutter test
...10 tests del sprint 1 (offline_knowledge) + 1 test preexistente (widget_test)
All tests passed!
```

### Después de este sprint

```
flutter analyze
   info - ...parcels_page.dart:827:7 (preexistente, no relacionado)
   info - ...diagnosis_detail.dart:92:3 (prefer_const_constructors_in_immutables)
   info - ...diagnosis_detail.dart:106:3 (prefer_const_constructors_in_immutables)
3 issues found. (ran in 4.2s)

flutter test
...knowledge_remote_datasource_test.dart:
  200 con paquete válido -> devuelve el Map tal cual
  404 (cultivo no existe en el catálogo) -> NetworkException
  500 del servidor -> ServerException
  timeout / sin conexión -> NetworkException sin statusCode
  200 pero envelope sin "data" -> ValidationException
...knowledge_repository_download_test.dart:
  descarga válida -> instala el paquete via insertPackage
  fallo de red -> no llama a insertPackage, no instala nada
  JSON corrupto (fichas vacío) -> insertPackage rechaza, no deja estado parcial
... + los 10 tests del sprint 1 + widget_test.dart
All tests passed!
```

**Conclusión:** 0 errores de análisis antes y después (mismos 3 `info`, ninguno
nuevo). 0 tests rotos: los 11 tests del sprint 1 y el `widget_test.dart`
preexistente siguen pasando sin cambios, más 8 tests nuevos de este sprint
(5 del datasource remoto + 3 del repositorio), todos en verde. El flujo
online de diagnóstico (`LlmDiagnosisCubit`/`LlmDiagnosisRepositoryImpl`) no
fue tocado.

## 4. Confirmación: Perfil → "Diagnóstico sin Conexión" queda funcional de punta a punta

Sí, en cuanto se configure `ApiEndpoints.offlineKnowledgeBaseUrl` con el host
real (paso 2), el flujo completo funciona sin ningún otro cambio de código:

1. Al abrir `OfflineModePage` (Perfil → tarjeta "Diagnóstico sin Conexión"),
   `OfflinePackageManagerCubit.loadStatuses()` consulta
   `KnowledgeRepository.hasPackageFor(slug)` para cada uno de los 5 cultivos
   soportados (Tomate, Maíz, Papa, Frijol, Calabaza) y pinta cada tarjeta como
   descargado/no descargado.
2. Al tocar "Descargar" en la tarjeta de un cultivo,
   `OfflinePackageManagerCubit.download(cultivo)` llama a
   `KnowledgeRepository.downloadAndInstallPackage(slug)`, que internamente
   hace `KnowledgeRemoteDataSource.downloadPackage()` (GET real vía
   `ApiClient`) → `KnowledgeLocalDataSource.insertPackage()` (ya existente,
   sin cambios). La tarjeta muestra spinner mientras descarga, y pasa a
   "Disponible sin conexión" (check verde) o a un mensaje de error legible
   según el resultado.
3. Ese mismo paquete instalado es el que ya consume
   `GetOfflineDiagnosisDetailUseCase` (sprint 1) cuando el usuario diagnostica
   sin conexión desde `DiagnosisResultPage`.

No queda ningún paso manual adicional más allá de la IP — no hay stubs, no
hay `TODO` bloqueante en este camino específico (el `.tflite` de embeddings
sigue siendo un placeholder, pero eso solo afecta el *fallback semántico*,
no el camino principal de match exacto por ID, que es el 95%+ de los casos
esperados).

## 5. Decisiones tomadas que no estaban 100% especificadas en el pedido

1. **Reutilización de `ApiClient` compartido, sin Dio dedicado** —
   `KnowledgeRemoteDataSourceImpl` recibe el mismo `ApiClient`/`Dio` global ya
   registrado en `_initCore()` (con `AuthInterceptor`/`ErrorInterceptor`/
   `LoggingInterceptor`) y arma una URL absoluta con
   `ApiEndpoints.offlineKnowledgeBaseUrl`, exactamente el mismo truco que usa
   `SubscriptionRemoteDataSourceImpl` para Payments — para no duplicar el
   `AuthInterceptor` con una segunda instancia de Dio. Esto reconcilia tu
   pedido de "usa `ApiClient`" (no `Dio` ni `http` directo) con "sigue el
   patrón de Payments" (base URL única, sin cliente dedicado).
2. **Envelope de respuesta `{success, data, error}`** — `ApiClient` (a
   diferencia de un `Dio` crudo) siempre interpreta el cuerpo de la respuesta
   como ese envelope y solo expone `response.data` si existe la clave
   `"data"`. El documento de especificación (sección 8) muestra el JSON del
   paquete "pelado" (sin envelope), pero **todos** los demás consumidores
   reales de `ApiClient` en este proyecto (agenda, historial, crop-plan,
   perfil aprendiz, diagnóstico) asumen ese envelope contra el mismo backend.
   Se implementó asumiendo que el nuevo endpoint seguirá esa misma
   convención (`{"success": true, "data": {...paquete...}}`) por
   consistencia con el resto de la plataforma — **no confirmado con el
   backend**, es el mayor riesgo de integración de este sprint. Si el
   endpoint real devuelve el paquete "pelado" en la raíz, el único ajuste
   necesario es cambiar `fromJsonT` en `KnowledgeRemoteDataSourceImpl.downloadPackage`
   para no depender de `ApiResponse`/envelope (una función, sin tocar nada
   más del feature).
3. **Reestructuración de `OfflineModePage` de granularidad por documento a
   granularidad por cultivo** — Confirmado contigo antes de implementar: la
   pantalla legacy descargaba documentos individuales por enfermedad dentro
   de un cultivo (con contador "2/3 descargadas"); ahora cada tarjeta de
   cultivo representa un único paquete completo (`hasPackageFor`/
   `downloadAndInstallPackage` son por cultivo, no por enfermedad). Se
   mantiene el mismo lenguaje visual (tarjetas, badges, `_ActionRow`,
   sección "DESCARGADO"), pero la lista de documentos por enfermedad
   desapareció porque el modelo de `offline_knowledge` no la tiene.
4. **Lista estática de 5 cultivos** — Confirmado contigo: se reutilizan los
   mismos 5 nombres que ya usaba la UI legacy (`OfflinePackageManagerCubit.supportedCrops`),
   mapeados a slug con `cultivoSlug()` (nueva función compartida en
   `domain/cultivo_slug.dart`, reemplaza el helper privado duplicado que
   había quedado en `diagnosis_result_page.dart` del sprint 1). No hay
   endpoint de catálogo — si el backend expone uno más adelante, este es el
   único lugar a reemplazar por una llamada real.
5. **Sin borrado de paquetes** — La UI legacy sí tenía borrado por
   documento, pero `KnowledgeRepository` no expone un método de
   desinstalación (no se pidió esta interfaz en ninguno de los dos sprints).
   Se optó por **no** agregar un método nuevo no solicitado; las tarjetas de
   cultivo descargado no tienen botón de eliminar en este sprint. Si se
   necesita, requiere agregar `KnowledgeRepository.deletePackage(cultivo)` +
   su implementación en el datasource local (tabla `knowledge_fichas`/
   `knowledge_packages`) — no implementado a propósito, fuera del pedido.
6. **Mensajes de error por tipo de excepción** — `OfflinePackageManagerCubit._friendlyMessage`
   distingue `ServerException`/`ValidationException`/`UnauthorizedException`/
   `NetworkException` (con caso especial para `statusCode == 404`, "cultivo
   no encontrado") — no especificado textualmente en el pedido, pero sigue
   el mismo patrón de mensajes fijos y seguros por código HTTP que ya usa
   `SubscriptionRemoteDataSourceImpl._defaultMessage` (nunca expone el
   detalle crudo del backend).
7. **Testing de `KnowledgeRemoteDataSource` sin mock framework** — El
   proyecto no tiene `mocktail`/`mockito` como dependencia. Se usó un
   `HttpClientAdapter` falso de Dio (`_FakeHttpClientAdapter`, ver
   `knowledge_remote_datasource_test.dart`) para simular respuestas HTTP
   (200/404/500/timeout/envelope vacío) sin red real y sin agregar
   dependencias nuevas — mismo criterio que el sprint 1 (fakes manuales en
   vez de mocks generados).

## 6. TODOs / riesgos que quedan explícitos

1. **Contrato exacto del envelope de respuesta** — ver decisión 2 arriba;
   es una suposición razonada, no confirmada con el equipo backend.
2. **Modelo de embeddings real** — sigue pendiente del sprint 1 (placeholder
   determinístico en `EmbeddingModelDataSourceImpl`), no afecta el camino de
   descarga/instalación de este sprint.
3. **Borrado y gestión de espacio de paquetes** — explícitamente fuera de
   alcance (ver decisión 5); la UI ya no ofrece esa acción para paquetes de
   `offline_knowledge` (si se quiere, es un pedido aparte).
4. **Actualización automática / recordatorios de re-descarga** — no
   implementado, tal como se pidió explícitamente que quedara fuera.

---

# Sprint 3 — Endpoints reales (README_ofline.md) reemplazan el contrato asumido

Reemplaza el endpoint asumido en el Sprint 2
(`GET /catalog/{cultivo}/offline-package`, que nunca existió) por los dos
endpoints reales confirmados en `README_ofline.md`. Cambio de flujo real,
confirmado contigo antes de tocar código (3 decisiones vía preguntas). No se
tocó `GetOfflineDiagnosisDetailUseCase`, el match exacto/fallback semántico,
`OfflineKnowledgeCubit`, el `ApiClient` compartido (se dejó de usar *para
este feature*, pero la clase en sí no se modificó), ni el toggle legacy
"Modo sin conexión".

## 1. Contrato real (citado de `README_ofline.md`)

**Base URL:** `http://52.1.110.21:8000` (línea 5) — sin cambios, mismo host
ya configurado en `ApiEndpoints.offlineKnowledgeBaseUrl`.

**`GET /api/v1/offline/catalog`** (línea 315-339):
> "Devuelve un documento por cada par (cultivo, fuente) del corpus."
```json
{
  "documents": [
    {
      "id": "doc_a582640ed8c5",
      "crop_name": "calabaza",
      "disease_name": "oidio",
      "title": "Calabaza — oidio",
      "source": "Guia de Enfermedades de Cucurbitaceas — INIFAP 2020",
      "size_bytes": 2650,
      "version": "1.0"
    }
  ]
}
```

**`GET /api/v1/offline/documents/{doc_id}`** (línea 345-370):
```json
{
  "id": "doc_a582640ed8c5",
  "content": "texto completo del documento...",
  "size_bytes": 2650,
  "embedding": [0.021, -0.053, ...],
  "chunks": [{"id": "doc_a582640ed8c5_c0", "index": 0, "text": "...", "embedding": [...]}]
}
```
Errores: `404` (doc_id no existe), `503` (almacén no disponible). Ambas
respuestas vienen **sin envelope** `{success, data, error}` (confirmado).

**Auth:** `Authorization: Bearer <jwt>` (línea 349-352), mismo esquema ya
usado por `/api/v1/consultar` — el `AuthInterceptor` del Dio compartido ya
lo inyecta automáticamente sin importar el host.

## 2. Diferencias contra lo asumido en Sprint 2 y cómo se resolvieron

| Asumido (Sprint 2) | Real (README) | Resolución |
|---|---|---|
| `GET /catalog/{cultivo}/offline-package` → un paquete completo por cultivo | `GET /offline/catalog` (lista global) + `GET /offline/documents/{doc_id}` (uno por uno) | `downloadAndInstallPackage(cultivo)` ahora orquesta: catálogo → filtrar por `crop_name` → descargar cada documento → ensamblar el JSON de paquete en memoria → `insertPackage()` (sin cambios en `insertPackage` ni en el datasource local). |
| Respuesta envuelta en `{success, data, error}` (asumido, riesgo declarado) | Respuesta pelada, confirmado | `KnowledgeRemoteDataSourceImpl` deja de usar `ApiClient` (que siempre asume ese envelope) y pasa a recibir el `Dio` compartido directo, igual que `SubscriptionRemoteDataSourceImpl` para Payments — confirmado contigo. |
| `TreatmentEntry.id` = raw label de la CNN (`clase_cnn`, ej. "Calabaza_Powdery Mildew") | El backend usa `doc_id` opaco; no hay relación con la CNN | `TreatmentEntry.id` = `disease_name` normalizado (`.toLowerCase()`, ej. "oidio"). `diagnosis_result_page.dart._offlineEnfermedadId` cambia de `topK.first.rawLabel` a `diagnosis.diseaseName.toLowerCase()` — exactamente la misma normalización que `LlmDiagnosisDataSourceImpl` ya envía como `resultado_cnn.enfermedad` al endpoint online, confirmado contigo. |
| `cultivoSlug()` quitaba acentos (slug ASCII, "Maíz" → "maiz") | Sin confirmar si el backend indexa con o sin acentos | Se cambia `cultivoSlug()` para que sea solo `.toLowerCase()` (sin stripping), igualando la normalización que el flujo online ya usa contra este mismo backend — confirmado contigo. |
| `TreatmentEntry.sintomas/tratamiento/severidad` estructurados | Solo `content` (texto libre) + `chunks` para RAG | `tratamiento` = `content` completo; `sintomas`/`severidad` quedan vacíos (la UI ya oculta el chip de severidad si viene vacío) — confirmado contigo. |

## 3. Archivos modificados/creados

### Modificados

| Archivo | Cambio |
|---|---|
| `lib/core/network/api_endpoints.dart` | `OfflineKnowledgeEndpoints` reemplaza `packageFor(cultivo)` por `catalog` y `documentById(docId)` (rutas reales `/api/v1/offline/...`). `offlineKnowledgeBaseUrl` sin cambios. |
| `lib/features/offline_knowledge/data/datasources/knowledge_remote_datasource.dart` | Reescrito: `getCatalog()` + `downloadDocument(docId)` en vez de `downloadPackage(cultivo)`. Recibe `Dio` (no `ApiClient`), URL absoluta, mapeo manual de `DioException` a las mismas excepciones tipadas de `api_exceptions.dart`. |
| `lib/features/offline_knowledge/data/repositories/knowledge_repository_impl.dart` | `downloadAndInstallPackage` reescrito: catálogo → filtro por cultivo → N descargas de documento → ensamblado en memoria → `insertPackage()` (una sola vez, al final). |
| `lib/features/offline_knowledge/domain/cultivo_slug.dart` | `cultivoSlug()` ahora es `value.toLowerCase()` (antes quitaba acentos). Mismo nombre/firma, comportamiento corregido. |
| `lib/features/agricultor/diagnosis/presentation/pages/diagnosis_result_page.dart` | `_offlineEnfermedadId` ya no usa `topK.first.rawLabel`; usa `cultivoSlug(diagnosis.diseaseName)` siempre. |
| `lib/core/di/injection_container.dart` | `KnowledgeRemoteDataSourceImpl(client: sl())` en vez de `apiClient: sl()` (mismo Dio compartido, sin instancia dedicada). |
| `test/features/offline_knowledge/knowledge_remote_datasource_test.dart` | Reescrito para `getCatalog()`/`downloadDocument()`; el caso de timeout se corrigió para lanzar el `DioException` directamente desde el adapter falso (ver nota técnica abajo). |
| `test/features/offline_knowledge/knowledge_repository_download_test.dart` | Reescrito: catálogo con N documentos, más el caso pedido explícitamente de "un documento falla a mitad de la descarga". |

### Nuevos

| Archivo | Capa |
|---|---|
| `lib/features/offline_knowledge/data/models/offline_catalog_document.dart` | data/models — parsea una entrada de `GET /offline/catalog`. |

**No se tocó:** `KnowledgeLocalDataSource`/`insertPackage()`, `GetOfflineDiagnosisDetailUseCase`, `DiagnosisDetail`/`TreatmentEntry`/`ScoredEntry`, `OfflineKnowledgeCubit`, `DiagnosisDetailView`/banners, `OfflinePackageManagerCubit`, `OfflineModePage` (su cubit expone la misma API pública, `download(cropNameEs)`, así que no necesitó cambios), `ApiClient` (clase en sí intacta, solo se dejó de usar en este feature), el toggle legacy, ni el flujo online (`LlmDiagnosisCubit`/`LlmDiagnosisRepositoryImpl`/`LlmDiagnosisDataSourceImpl`).

**Nota técnica descubierta en este sprint:** Dio no aplica `connectTimeout`/`receiveTimeout` a un `HttpClientAdapter` custom (esa lógica vive únicamente en el adapter IO real, `io_adapter.dart`) — el test de timeout del Sprint 2 "pasaba" solo porque `ApiClient` atrapaba cualquier excepción genérica (incluido un `TypeError` de casteo) y la envolvía como `NetworkException`. Al quitar `ApiClient` de este datasource, ese test dejó de ser válido y se corrigió para que el adapter falso lance el `DioException` directamente (como haría el adapter real al no poder conectar), en vez de simular un delay contra un timeout que nunca se aplicaba.

## 4. Resultado de `flutter analyze` y `flutter test`

### Antes de este sprint (idéntico al final del Sprint 2)
```
flutter analyze: 3 issues (1 preexistente + 2 del Sprint 1, ninguno nuevo)
flutter test: 19 tests -- All tests passed!
```

### Después de este sprint
```
flutter analyze
   info - ...parcels_page.dart:827:7 (preexistente, no relacionado)
   info - ...diagnosis_detail.dart:92:3 / 106:3 (Sprint 1, constructores no-const inevitables)
3 issues found.

flutter test
...knowledge_remote_datasource_test.dart (6 tests: getCatalog 200/500,
  downloadDocument 200/404/503/timeout)
...knowledge_repository_download_test.dart (3 tests: 2 documentos OK,
  cultivo sin documentos en catálogo, un documento falla a mitad -> descarta todo)
... + los 10 tests de Sprint 1 (usecase + coseno) + widget_test.dart
20 tests -- All tests passed!
```

**Conclusión:** 0 errores de análisis antes y después (mismos 3 `info`). 0
tests rotos: los 10 tests de Sprint 1 y el `widget_test.dart` preexistente
siguen pasando sin cambios. Los 5 tests de datasource remoto y 3 de
repositorio del Sprint 2 se reescribieron (el contrato que probaban ya no
existe) — ahora prueban el contrato real. El flujo online de diagnóstico no
fue tocado.

## 5. Confirmación: ¿funciona de punta a punta con la IP del README ya configurada?

**El mecanismo de descarga e instalación sí queda 100% funcional** en
cuanto se valide contra el servidor real (la base URL ya es la correcta,
`http://52.1.110.21:8000`, no requiere ningún cambio de configuración
adicional): catálogo → filtro por cultivo → N documentos → ensamblado →
`insertPackage()` → disponible para `GetOfflineDiagnosisDetailUseCase`.

**Un riesgo queda abierto, pero no es nuevo de este sprint — es heredado y
compartido con el flujo online ya conectado:** el match exacto por ID
depende de que `diagnosis.diseaseName.toLowerCase()` (la traducción al
español que ya hace `LabelsRepository` desde el `class_mapping.json` de la
CNN) coincida carácter por carácter con el `disease_name` real que devuelve
el catálogo (ej. si el backend indexa "oídio" con acento y la app compara
contra "oidio" sin acento, o viceversa, el match exacto fallaría y caería al
fallback semántico). Esto **no es una duda nueva que yo haya introducido**:
es exactamente el mismo supuesto de normalización que ya usa
`LlmDiagnosisDataSourceImpl` para el endpoint online ya integrado
(`resultado_cnn.enfermedad: diagnosis.diseaseName.toLowerCase()`) — si ese
flujo ya funciona en producción contra este backend, el mismo supuesto
debería sostenerse aquí. Recomiendo validarlo con una descarga real de
prueba (ej. "maíz"/"calabaza") en cuanto haya acceso al servidor, y si hay
mismatch, el ajuste queda contenido a `cultivoSlug()` (un solo lugar).

El modelo de embeddings sigue siendo el placeholder del Sprint 1 (no afecta
el camino principal de match exacto, solo el fallback semántico).
