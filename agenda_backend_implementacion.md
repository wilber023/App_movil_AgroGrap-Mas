# Implementación — Agenda/Seguimiento (Parte 2), backend real

> Sprint exclusivo de la Parte 2 del `README_CLUSTERING_MAPA_Y_AGENDA.md`
> (agenda auto-generada por rol). La Parte 1 (mapa epidemiológico / banner
> de Home) **no se tocó** — confirmado con `git diff --stat`, diff vacío.

---

## 1. Resultado del PASO 1 (investigación)

### 1.1 `AgendaRemoteDataSourceImpl` — estado antes de este sprint

`lib/features/aprendiz/agenda/data/datasources/agenda_remote_datasource.dart`:
3 métodos (`getAgendaOverview`, `completeActivity`, `postponeActivity`), **sin
`generar`**. Sin Dio propio: usaba `ApiClient` inyectado, resuelto al Dio
**sin nombre** de `_initCore()` con `baseUrl = 'http://174.129.218.190/api/v1'`
(microservicio de **Usuarios**, no `52.1.110.21:8000`). Rutas hardcodeadas a
`/aprendiz/...` en `AgendaEndpoints`, con el comentario literal `// TODO:
reemplazar por la URL real cuando el backend exponga el modulo`. No soportaba
`agricultor` en ningún punto.

### 1.2 Divergencia real entre perfiles

Aprendiz tenía un feature "Agenda" completo (Clean Architecture, patrón
`isPendingSync`/`NetworkInfo`), con datos **de ejemplo sembrados**
(`_seedOverview()`: "Calabaza", "Desarrollo Vegetativo"), no reales.

**Agricultor no tenía "Agenda" — tenía "Treatment"** (`lib/features/agricultor/treatment/`).
Corrijo aquí un dato que me reportó mal el primer agente de exploración: dijo
que `TreatmentBloc` recargaba desde un `TreatmentRemoteDataSourceImpl`
mockeado. Verifiqué el código directamente: ese archivo existía pero era
**código muerto** (sin referencias en ningún otro archivo, sin registro en
DI — confirmado con grep). `TreatmentRepositoryImpl` solo usaba
`TreatmentLocalDataSource`, que sí era real: computaba 3 pasos fijos con
fechas +0/+7/+14 días desde el diagnóstico, 100% en Hive, sin backend.

- **Botón "Agregar a la agenda" (Agricultor)**: `diagnosis_result_page.dart:153-206`,
  `_addToAgenda()`. Guardaba un flag Hive y recalculaba localmente.
- **Botón "Agregar a mi agenda" (Aprendiz)**: `aprendiz_recommended_action_page.dart:120-141`.
  Verifiqué el código: **era un no-op real** — solo navegaba a
  `AprendizAgendaPage()`, sin guardar ni usar `tratamiento`/`prevencion` del
  diagnóstico.
- `.../agenda/generar` no existía en ningún `.dart` del proyecto — 100% nuevo.

### 1.3 Patrón local-first ya establecido

`AgendaActivityEntity.isPendingSync` / `CropActivityEntity.isPendingSync`
(mismo patrón en `aprendiz/cultivo`): si `NetworkInfo.isConnected` → intenta
remoto, fallback a caché si falla; si no hay red → guarda local con
`isPendingSync: true`. Sin worker de reconciliación automática (mismo gap ya
documentado en el sprint de notificaciones) — no se tocó, sigue igual.
**Se reutilizó tal cual**, no se inventó un patrón nuevo.

### 1.4 `llmDio`

Reutilizable agregando `/api/v1` a cada path (igual que
`LlmEndpoints.consultar`), ya que `llmBaseUrl` es solo el host.

### 1.5 Pruebas reales contra el backend (con `--data-binary @archivo`;
`-d` inline con `\n` en comillas simples de bash corrompía el body — nota
para quien reproduzca esto)

**Rol `agricultor`:**
```
POST /agricultor/agenda/generar  -> 200, 4 actividades (2 tratamiento + 2 prevención)
GET  /agricultor/agenda           -> 200, mismas 4 actividades (persistidas)
POST .../activities/act_1/complete -> 200, status: "completed"
POST .../activities/act_2/postpone {"reason":"lluvia"} -> 200, status: "postponed"
POST .../activities/act_no_existe/complete -> 404
```

**Rol `aprendiz`:**
```
GET  /aprendiz/agenda (usuario nuevo, antes de generar) -> 200, vacío
POST /aprendiz/agenda/generar    -> 200, 3 actividades
GET  /aprendiz/agenda             -> 200, mismas 3 actividades
POST .../activities/act_1/complete -> 200, status: "completed"
```

**Auth:** sin token → 401. **Observación** (no bloqueante): un token con
`rol: "aprendiz"` pudo leer `GET /agricultor/agenda` (200, no 403) — el
backend particiona por `sub` + rol de la URL, no valida el claim `rol` del
JWT contra la ruta. No afecta a la app (siempre llama la ruta correcta según
la pantalla), queda anotado.

### 1.6 Decisión confirmada contigo antes de tocar código

El backend **reemplaza toda la agenda del usuario+rol en cada `generar`**
(un solo plan activo). Agricultor soportaba múltiples tratamientos
simultáneos. Confirmaste adoptar el modelo de **un solo plan activo por
perfil**, con confirmación al usuario si ya tenía uno. Implementado así en
ambos perfiles (ver sección 3).

---

## 2. Archivos creados / modificados

### Nuevos

- `lib/features/aprendiz/agenda/domain/usecases/generate_agenda_usecase.dart`
- `test/features/aprendiz/agenda/agenda_remote_datasource_test.dart`
- `test/features/aprendiz/agenda/agenda_repository_impl_test.dart`

### Modificados — capa compartida (reutilizada por ambos perfiles)

- `lib/core/network/api_endpoints.dart` — `AgendaEndpoints` ahora recibe
  `rol` en cada método + `generar(rol)`, con prefijo `/api/v1`.
- `lib/features/aprendiz/agenda/data/datasources/agenda_remote_datasource.dart` —
  reescrito: usa `Dio` (`llmDio`) en vez de `ApiClient`, cada método recibe
  `rol`, nuevo `generar()`.
- `lib/features/aprendiz/agenda/domain/repositories/agenda_repository.dart` —
  agrega `generarAgenda(...)`.
- `lib/features/aprendiz/agenda/data/repositories/agenda_repository_impl.dart` —
  agrega `rol` (fijo por instancia) + `generarAgenda` (requiere conexión,
  `Left(NetworkFailure())` si no hay red — generar un plan nuevo depende del
  cálculo del backend, no se inventa localmente).
- `lib/features/aprendiz/agenda/data/datasources/agenda_local_datasource.dart` —
  el fallback sin caché ya no siembra datos de ejemplo ("Calabaza"); ahora
  devuelve el mismo "vacío" que el backend real para un usuario nuevo
  (confirmado con curl).
- `lib/features/aprendiz/agenda/dependency_injection/agenda_injection_container.dart` —
  Dio → `llmDio`, `rol: 'aprendiz'`, registra `GenerateAgendaUseCase`.

### Modificados — Aprendiz

- `lib/features/aprendiz/diagnostico/presentation/pages/aprendiz_recommended_action_page.dart` —
  el botón "Agregar a mi agenda" ahora llama `GenerateAgendaUseCase` real
  (con `tratamiento`/`prevencion` del diagnóstico actual), con diálogo de
  reemplazo si ya había un plan activo.

### Modificados — Agricultor (reescritura del feature Treatment)

- `lib/features/agricultor/treatment/domain/repositories/treatment_repository.dart` —
  agrega `generateFromDiagnosis(...)`.
- `lib/features/agricultor/treatment/data/repositories/treatment_repository_impl.dart` —
  **reescrito por completo**: ya no escanea `diagnosisBox`; depende de
  `AgendaRepository` (rol `agricultor`) para el overview real + fallback
  offline, y de `TreatmentLocalDataSource` (también reescrito) solo para lo
  que el backend no modela (ver sección 3).
- `lib/features/agricultor/treatment/data/datasources/treatment_local_datasource.dart` —
  reescrito: de "escanear Hive por cada diagnóstico" a "guardar un estado
  local complementario" (metadatos del diagnóstico origen, overrides de
  reprogramación de fecha, marca de hora de completado, flag de
  recordatorios).
- `lib/features/agricultor/treatment/data/datasources/treatment_remote_datasource.dart` —
  **eliminado** (código muerto confirmado, sin referencias en el proyecto).
- `lib/features/agricultor/treatment/domain/usecases/treatment_usecases.dart` —
  agrega `GenerateTreatmentFromDiagnosisUseCase`.
- `lib/features/agricultor/treatment/presentation/bloc/treatment_bloc.dart` —
  agrega el evento `TreatmentGenerateFromDiagnosisRequested`.
- `lib/features/agricultor/diagnosis/presentation/pages/diagnosis_result_page.dart` —
  `_addToAgenda()` ahora llama al backend real vía `TreatmentBloc`, con el
  mismo diálogo de reemplazo si ya había un plan activo.
- `lib/core/di/injection_container.dart` — `_initTreatmentFeature()` registra
  una segunda instancia de `AgendaRepository` (rol `'agricultor'`,
  `instanceName: 'agricultorAgendaRepository'`), reutilizando el **mismo**
  `AgendaRemoteDataSource` genérico que Aprendiz (sin duplicar la lógica de
  red), con su propia caché en la caja Hive `'agendaBox'` ya existente.

---

## 3. Cómo quedó resuelta la sincronización local vs remota

**Una sola capa de red/parseo/errores, reutilizada por ambos perfiles**: el
`AgendaRemoteDataSource` es un singleton genérico (recibe `rol` por
llamada). Cada perfil registra su propia instancia de `AgendaRepository`
(con `rol` fijo + su propia caché Hive), evitando duplicar la lógica
offline-first que ya existía en Aprendiz.

- **Lectura (`GET`)**: si hay conexión, pide al backend y cachea; si falla o
  no hay conexión, sirve la última caché de Hive — sin romperse, sin perder
  datos (cubierto por tests).
- **`generar`**: requiere conexión explícitamente (`NetworkFailure` si no
  hay red) — el cálculo del calendario lo hace el backend (LLM o regla
  determinista); no se fabrica un plan localmente para no duplicar esa
  lógica ni inventar un dato que no existe todavía.
- **`complete`**: intenta el backend si hay red; si falla o no hay conexión,
  aplica el cambio en la caché local con `isPendingSync: true` (mismo patrón
  ya existente, no inventado).
- **`postpone`** (endpoint real, marca "pospuesto" sin mover fecha): queda
  conectado para Aprendiz (que ya tenía esa acción en su UI). **Agricultor no
  tiene un botón "posponer con motivo" — tiene "reprogramar a una fecha
  específica" (`treatment_detail_page.dart`, `showDatePicker`), que el
  backend no soporta** (no hay endpoint para mover a fecha arbitraria).
  Decisión: `rescheduleStep` de Agricultor se mantiene **100% local**
  (override de fecha sobre la actividad cacheada, exactamente como ya
  funcionaba antes de conectar el backend) — no se fuerza esa acción contra
  `postpone`, que tiene una semántica distinta.
- **Agricultor**: modelo de **un solo plan activo** (confirmado contigo).
  `TreatmentEntity` se reconstruye combinando el overview real del backend
  (actividades) con el estado local complementario (nombre de enfermedad,
  textos del LLM que el backend no devuelve en el overview, overrides de
  fecha, hora de completado, flag de recordatorios).

---

## 4. `flutter analyze` / `flutter test`

| | Antes de este sprint | Después |
|---|---|---|
| `flutter analyze` | 3 issues (`info`, preexistentes) | **Mismos 3 issues**, cero nuevos |
| `flutter test` | 32/32 pasan | **43/43 pasan** (+11 tests nuevos de agenda) |

Tests nuevos:
- `agenda_remote_datasource_test.dart`: `generar` 200 (datos reales del
  README), `GET` 200 con overview y 200 vacío (usuario nuevo), 401,
  `complete`/`postpone` 200, `complete` sobre actividad inexistente → 404.
- `agenda_repository_impl_test.dart`: sin conexión y sin caché → overview
  vacío sin reventar; sin conexión con caché previa → sigue mostrando esa
  caché; sin conexión al completar → guarda local con `isPendingSync: true`;
  `generarAgenda` sin conexión → `NetworkFailure`, sin inventar un plan.

---

## 5. Confirmación — nada más se vio afectado

- **Clustering (mapa epidemiológico / banner de Inicio):** `git diff --stat -- lib/features/clustering/` → **vacío**.
- **Diagnóstico (`/consultar`, campo `rol`):** `git diff --stat -- lib/features/agricultor/diagnosis/data/datasources/llm_diagnosis_datasource.dart` → **vacío**.
- **Payments/Subscription:** `git diff --stat -- lib/features/subscription/` → **vacío**.
- **Notificaciones (con su fix ya aplicado):** sin cambios nuevos en este
  sprint — el diff de `lib/features/notifications/` que muestra `git status`
  corresponde íntegramente al sprint anterior ya confirmado, no a este.

---

## 6. Seguimiento — migración, bug encontrado, y verificación real

Tras la primera entrega, se pidió verificar explícitamente qué pasa con
datos/usuarios existentes y probar los flujos de UI. Resultado:

### 6.1 Migración del formato viejo — probado con Hive real, no un fake

Nuevo test: `test/features/agricultor/treatment/treatment_local_datasource_migration_test.dart`.
Usa una caja Hive **real** en un directorio temporal (no un fake en memoria)
con exactamente las claves que escribía el código anterior a este sprint
(`agenda_added_$id`, `treatment_$id`, `reschedule_${id}_$stepId`,
`reminders_$id`). Confirmado:
- `getState()` **no revienta** — devuelve `null` (sin plan migrado).
- Las claves viejas **quedan intactas en disco**, sin borrarse.
- Guardar el estado nuevo (`treatment_local_state`) no colisiona con ellas
  (namespace de claves distinto).

**Conclusión para un usuario que actualiza la app:** sus datos no se pierden
del disco, pero se vuelven invisibles para la UI — ve la Agenda vacía, igual
que un usuario nuevo, hasta que vuelva a generar un plan (que sí queda
correctamente conectado al backend desde ese momento).

### 6.2 Bug real encontrado y corregido: checkmark obsoleto por diagnóstico

`diagnosis_result_page.dart` seguía leyendo el flag viejo
`agenda_added_$diagnosisId` (nunca se limpiaba) para decidir si mostrar
"Tratamiento en agenda" (check verde, botón deshabilitado). Con el modelo
de un solo plan activo, si el diagnóstico A se agregaba y luego B lo
reemplazaba, A seguía marcado como "en agenda" para siempre — una
inconsistencia visible real, no solo teórica.

**Corregido:** se agregó `diagnosisId` al estado que guarda el plan activo
(`TreatmentRepositoryImpl.generateFromDiagnosis`), y un nuevo método
`TreatmentRepository.isActivePlanFor(diagnosisId)` (lectura local, sin red)
que compara contra ese `diagnosisId` en vez de un flag que nunca se limpia.
Archivos: `treatment_repository.dart`, `treatment_repository_impl.dart`,
`treatment_usecases.dart` (nuevo `IsActivePlanForUseCase`), `treatment_bloc.dart`,
`diagnosis_result_page.dart` (ya no usa la caja Hive directamente — se quitó
la dependencia de `hive` en este archivo). Cubierto por la prueba #2 de la
sección 6.4.

### 6.3 Decisión confirmada sobre usuarios con varios tratamientos previos

Se te presentó el hallazgo explícitamente (un Agricultor con 2-3
tratamientos guardados localmente ve la Agenda vacía tras actualizar, sin
que el reporte original lo hubiera decidido) y **confirmaste aceptar la
pérdida de visibilidad** — no se construye migración automática. Los datos
viejos quedan huérfanos en Hive (ver 6.1), disponibles si en el futuro se
decide migrarlos, pero el usuario debe volver a agregar su tratamiento
activo manualmente.

### 6.4 Verificación de los 5 escenarios de UI pedidos

**No hay emulador Android disponible en este entorno** (`flutter emulators`
→ ninguno configurado). Se intentó un build de Windows desktop como
alternativa visual, pero **falló por una limitación del entorno ajena a
este sprint**: el SDK de Firebase para Windows requiere CMake ≥ 3.22 y el
sistema tiene 3.20 (`CMake Error ... cmake_minimum_required`). Tampoco hay
credenciales de una cuenta real para autenticar contra el backend en
producción, ni cámara disponible para el flujo de captura de diagnóstico —
ambos necesarios para recorrer la app de punta a punta manualmente.

En su lugar, se cubrieron los 5 escenarios pedidos con tests automatizados
y repetibles a nivel de repositorio, usando cajas Hive **reales** (no fakes)
para que la persistencia sea fiel:

`test/features/agricultor/treatment/treatment_repository_impl_test.dart`:
1. Diagnosticar y "Agregar a la agenda" → aparece el plan real (no vacío,
   no error). ✅
2. Repetir con otro cultivo → reemplaza el plan anterior por completo, y el
   checkmark del diagnóstico viejo ya no se muestra (bug de 6.2 cubierto
   aquí). ✅
3. Marcar una actividad como completada → persiste tras "cerrar y reabrir
   la app" (nueva instancia del repositorio sobre la misma caja Hive ya en
   disco, sin reutilizar nada en memoria). ✅
5. Generar sin conexión → `Left(NetworkFailure)`, mensaje claro, sin
   crash, sin inventar un plan local. ✅

`test/features/aprendiz/agenda/agenda_repository_impl_persistence_test.dart`:
4. Mismo escenario (generar + completar + persistencia tras reinicio) para
   Aprendiz. ✅

**Hallazgo adicional durante esta verificación:** el primer intento de
estos tests reveló que `getAgenda()` (una simple lectura) podía fallar por
completo si el plugin de notificaciones locales no estaba inicializado
(`LateInitializationError` al sincronizar el recordatorio del paso activo).
Es un problema preexistente (el código anterior a este sprint tenía la
misma dependencia sin protección), pero como se detectó tocando este mismo
archivo, se corrigió: `_syncReminder` ahora está envuelto en `try/catch`
dentro de `TreatmentRepositoryImpl._buildEntity` — sincronizar el
recordatorio es un efecto secundario best-effort; un fallo ahí ya no puede
tumbar la lectura real de la agenda.

**Lo que NO se pudo verificar por no tener dispositivo/emulador:** el
renderizado visual exacto de los diálogos (colores, textos en pantalla,
animaciones) y el comportamiento real de `showDialog`/`Navigator` en
conjunto. La lógica que cada diálogo dispara sí está cubierta por los tests
anteriores.

### 6.5 `flutter analyze` / `flutter test` (tras este seguimiento)

| | Antes de este seguimiento | Después |
|---|---|---|
| `flutter analyze` | 3 issues (preexistentes) | **Mismos 3 issues**, cero nuevos |
| `flutter test` | 43/43 pasan | **50/50 pasan** (+7 tests nuevos) |

`git status`/`git diff --stat` confirman que esta vuelta solo tocó archivos
de Treatment/Agenda/diagnosis_result_page ya mencionados — clustering,
notificaciones, `/consultar` y payments siguen sin cambios.

---

## 6. Fuera de alcance — visto pero NO tocado

1. **Reconciliación automática de `isPendingSync`.** Ni Agenda ni Treatment
   tienen un worker que reintente cambios pendientes cuando vuelve la
   conexión (mismo gap ya documentado en notificaciones). No se tocó en
   este sprint.
2. **`postpone` de Agricultor.** El backend no ofrece "mover a fecha
   arbitraria"; Agricultor solo tiene "reprogramar" (con selector de fecha),
   que se mantiene local. Si se quiere que Agricultor también tenga un
   "posponer con motivo" real contra el backend, sería una función de UI
   nueva, no solo conectar un endpoint existente — no se agregó sin que me
   lo pidieran explícitamente.
3. **Efecto colateral esperado de quitar el seed falso de Aprendiz:** un
   Aprendiz que nunca generó una agenda ahora ve "Próxima actividad" vacía
   en Inicio (antes siempre mostraba una de las 3 actividades de ejemplo
   "Calabaza"). Es la consecuencia correcta de dejar de inventar datos, pero
   lo anoto por si el diseño de Inicio para ese estado vacío necesita
   revisión visual aparte (no se tocó ningún widget de Inicio en este
   sprint, más allá del efecto de este cambio en los datos que consume).
