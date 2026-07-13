# Implementación — Mapa Epidemiológico (Clustering), Parte 1

> Sprint: solo la Parte 1 del `README_CLUSTERING_MAPA_Y_AGENDA.md` (mapa
> epidemiológico / clustering por estado). La Parte 2 (agenda remota) **no**
> se tocó — el backend no expone esas rutas; la app sigue con Hive local.

---

## 1. Resultado de la investigación (PASO 1)

### 1.1 Pantalla de Inicio por perfil

No comparten ningún widget base — son features independientes:

- **Agricultor**: `lib/features/agricultor/home/presentation/pages/home_page.dart`
  (`HomePage`, monolítico, secciones como métodos privados).
- **Aprendiz**: `lib/features/aprendiz/inicio/presentation/pages/aprendiz_home_page.dart`
  (`AprendizHomePage` → `_AprendizHomeView` → `_HomeContent`), compone
  widgets modulares en `presentation/widgets/`.

El switch de rol ocurre en navegación (`splash_page.dart`, `login_page.dart`),
según `ProfileType` → `MainShell` (Agricultor) vs `AprendizMainShell`
(Aprendiz), no en un widget compartido.

**Hallazgo clave que cambió el alcance de la implementación**: ya existía
infraestructura *placeholder* pensada exactamente para este sprint:

- Aprendiz tenía `PhytosanitaryAlertEntity` (`level: none/low/moderate/high`)
  ya integrada en el overview de Inicio, alimentada por un datasource local
  que **siempre devolvía `.none`**, con un comentario explícito: *"mientras
  el backend no expone el endpoint correspondiente... nunca un dato
  inventado"*.
- Agricultor tenía un botón **"Ver mapa de alertas"** que solo abría un
  snackbar de "próximamente", leyendo datos de un dashboard **100% mockeado**
  (`HomeRemoteDataSourceImpl` hardcodea nombre, parcelas y alertas fake).

Ambos quedaron reemplazados por datos reales en este sprint (ver sección 2).

### 1.2 Sistema de notificaciones existente

Vive en `lib/features/notifications/` (Clean Architecture) + dos servicios
puente en `lib/core/services/`: `PushNotificationService` (push FCM remoto)
y `NotificationService` (recordatorios locales programados, canal
`agenda_reminders`, usado solo por Tratamientos).

- No hay banner/overlay in-app genérico; lo más cercano es la propia
  pantalla `NotificationsPage` (historial).
- No hay `enum NotificationType` ni discriminador de tipo — el modelo es
  plano.
- **El backend de notificaciones es un microservicio aparte**
  (`3.218.172.128:8100`, ver `integrar_notificaciones.md`): revisa cada hora
  si cambió la campaña dominante del estado suscrito y **envía el push él
  mismo**. La app solo se suscribe (`POST /suscripciones`); no existe manera
  de disparar un push inmediato desde la app para esta alerta.

**Limitación reportada (no se improvisó nada):** no se creó ningún
mecanismo de notificación nueva. El propio banner en Inicio (sección 2.3)
cumple el rol de "notificación in-app" al mostrar la alerta apenas se abre
la pantalla — es honesto con lo que la app puede hacer hoy, en vez de forzar
una notificación local del dispositivo reutilizando el canal
`agenda_reminders` (semánticamente ajeno a esto) o fingir un push que la app
no puede disparar.

### 1.3 Fuente de la región del usuario — el bloqueante

- `UserEntity`/`UserModel` (Auth): sin ningún campo de dirección/estado.
- Sin GPS/geolocalización en toda la app (ningún paquete `geolocator`/`location`).
- `ParcelEntity.region`: texto libre por parcela, sin catálogo, capturado
  para otro propósito (identificar la parcela).
- **Fuente elegida, confirmada contigo**: `NotificationPreferencesEntity.estado`,
  del feature de notificaciones — capturado en Ajustes > Notificaciones
  específicamente para "alertas por estado", con un comentario del propio
  código reconociendo el mismo problema: *"La app no tiene hoy un catálogo
  confiable de estados... el usuario lo escribe él mismo una sola vez"*.
  Se lee con `GetNotificationPreferencesUseCase` (100% local, sin red).
  Si está vacío (usuario nunca lo configuró), se consulta la **alerta
  nacional** (`estado: null`) — comportamiento explícitamente soportado por
  el backend, confirmado con una llamada real (ver sección 4).

### 1.4 `llmDio` / `AuthInterceptor`

Confirmado con llamada real (ver sección 4): `ApiEndpoints.llmBaseUrl =
'http://52.1.110.21:8000'`, Dio `'llmDio'` con `AuthInterceptor` que inyecta
`Authorization: Bearer` desde `TokenStorage`.

### 1.5 `ApiEndpoints`

No existía `ClusteringEndpoints` ni rutas `/clustering`/`/alertas`. Se creó
desde cero (ver sección 2).

---

## 2. Archivos creados / modificados

### Nuevos (feature `clustering`, Clean Architecture completa)

```
lib/features/clustering/
  domain/
    entities/estado_resumen_entity.dart        (EstadoResumenEntity, MapaCampaniasEntity)
    entities/alerta_epidemiologica_entity.dart  (AlertaEpidemiologicaEntity)
    repositories/clustering_repository.dart
    usecases/get_mapa_campanias_usecase.dart
    usecases/get_alerta_usecase.dart            (+ GetAlertaParams)
  data/
    models/estado_resumen_model.dart            (EstadoResumenModel, MapaCampaniasModel)
    models/alerta_epidemiologica_model.dart
    datasources/clustering_remote_datasource.dart  (reusa Dio 'llmDio')
    repositories/clustering_repository_impl.dart
  presentation/
    cubit/epidemiological_map_cubit.dart        (mapa completo, on-demand)
    cubit/epidemiological_alert_cubit.dart       (alerta del Home: resuelve estado + consulta)
    widgets/estado_resumen_tile.dart
    widgets/epidemiological_alert_banner.dart
    pages/epidemiological_map_page.dart          (pantalla compartida Agricultor/Aprendiz)

test/features/clustering/clustering_repository_impl_test.dart
```

### Modificados

- `lib/core/network/api_endpoints.dart` — agrega `ClusteringEndpoints`
  (`mapaCampanias`, `alertas`).
- `lib/core/di/injection_container.dart` — `_initClusteringFeature()`,
  reutiliza `sl<Dio>(instanceName: 'llmDio')` ya registrado por el feature
  de diagnóstico.
- `lib/features/agricultor/home/presentation/pages/home_page.dart` —
  reemplaza `_buildRegionalAlertCard` (leía `DashboardEntity.recentAlerts`,
  **100% mock**) por `_buildEpidemiologicalAlertBanner`, independiente del
  `HomeBloc` mockeado, con datos reales. Se eliminó `_showComingSoon` (ya sin
  uso: era solo para los dos placeholders del banner viejo).
- `lib/features/agricultor/profile/presentation/pages/profile_page.dart` —
  entrada "Mapa epidemiológico".
- `lib/features/aprendiz/perfil/presentation/pages/aprendiz_profile_page.dart` —
  entrada "Mapa epidemiológico".
- `lib/features/aprendiz/inicio/data/repositories/aprendiz_home_repository_impl.dart` —
  reemplaza `PhytosanitaryAlertLocalDataSource` por
  `GetAlertaUseCase` + `GetNotificationPreferencesUseCase`
  (`_resolvePhytosanitaryAlert`).
- `lib/features/aprendiz/inicio/dependency_injection/aprendiz_home_injection_container.dart` —
  DI actualizada.
- `lib/features/aprendiz/inicio/domain/entities/phytosanitary_alert_entity.dart` —
  comentario actualizado (ya no referencia el datasource local eliminado).
- `lib/features/aprendiz/inicio/presentation/pages/aprendiz_home_page.dart` —
  oculta `HomePhytosanitaryAlertCard` por completo cuando no hay alerta
  activa (antes siempre mostraba el mensaje neutral), reacomoda el layout
  con el fun fact card cuando corresponde.

### Eliminado

- `lib/features/aprendiz/inicio/data/datasources/phytosanitary_alert_local_datasource.dart`
  — placeholder ya cumplido, reemplazado por datos reales; se eliminó en vez
  de dejarlo como código muerto.

---

## 3. Integración con notificaciones y limitación encontrada

No se agregó ningún mecanismo de notificación nuevo. Se reutilizó
`NotificationPreferencesEntity.estado` (lectura local, sin tocar el feature)
como fuente de región. El "aviso" de la alerta activa es el banner en
Inicio de ambos perfiles — se muestra apenas se abre la pantalla, cumple el
rol de notificación in-app.

**Limitación real, no un rodeo**: el sistema de notificaciones push de este
proyecto es enteramente server-driven (microservicio en
`3.218.172.128:8100`, cron de una hora); la app no tiene forma de disparar
un push inmediato. El único mecanismo local disponible
(`NotificationService.instance.scheduleReminder`) es para recordatorios de
Agenda con su propio canal (`agenda_reminders`) — reusarlo aquí habría sido
forzar una notificación fuera de su propósito original.

---

## 4. `flutter analyze` / `flutter test`

| | Antes | Después |
|---|---|---|
| `flutter analyze` | 3 issues (`info`, preexistentes, ajenos a este sprint) | **Mismos 3 issues**, cero nuevos |
| `flutter test` | 20/20 pasan | **27/27 pasan** (20 + 7 nuevos de `ClusteringRepositoryImpl`) |

## 5. Prueba real contra el backend

Se generó un token de desarrollo real y se probaron los endpoints tal como
los va a consumir la app:

```
POST /api/v1/dev/token           -> 200, token emitido
GET  /clustering/mapa-campanias  -> 200, 584 campañas, estados ordenados por superficie
GET  /alertas                    -> 200, alerta nacional real (Plagas de los Cítricos)
GET  /alertas?estado=Chiapas     -> 200, alerta específica de Chiapas
GET  /alertas (sin token)        -> 401, como se documenta
```

## 6. Qué NO se implementó, y por qué

**Parte 2 del README (agenda remota) no se tocó.** El backend no expone
`/aprendiz/agenda`, `/aprendiz/agenda/activities/{id}/complete` ni
`/postpone` — implementarlas habría sido código muerto apuntando a rutas
inexistentes. La agenda sigue 100% local (Hive), sin cambios.

Tampoco se implementó ningún "clustering de agenda" (inteligencia colectiva
a partir de diagnósticos de usuarios en tiempo real) — ese concepto no
corresponde a este sprint ni existe en el backend; el clustering
implementado es exclusivamente el de campañas SENASICA por estado descrito
en la sección 2 del README.
