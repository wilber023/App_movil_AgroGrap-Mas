# Fix — Guardar en Ajustes > Notificaciones bloqueaba la UI por el timeout del microservicio de push

## 1. Causa exacta (PASO 1)

**No es un bug introducido en el sprint de clustering.** Confirmado con
`git diff --stat -- lib/features/notifications/ lib/core/services/` contra
el estado del repo al empezar ese sprint: **vacío** — ningún archivo de
notificaciones ni de `core/services/` fue tocado al implementar el mapa
epidemiológico. Mi único cambio en `injection_container.dart` en ese sprint
fue agregar la función nueva `_initClusteringFeature()` *después* de
`_initNotificationsFeature()`, sin modificar esta última (diff verificado
línea por línea, ver `git diff` de ese archivo).

`git blame` sobre el método afectado confirma que el código es preexistente,
introducido en el commit `5d74690` ("PRUEBAS-DIAGNOSTICOS-LLM+NOTIFICACION",
2026-07-12 04:00:22), el commit que ya estaba en la punta del branch antes de
que empezara a trabajar en clustering.

**Causa raíz:** en
`lib/features/notifications/presentation/bloc/notification_subscription_bloc.dart`,
`_onSubscribeRequested` (y de forma simétrica `_onUnsubscribeRequested`)
guardaba la preferencia localmente (`_savePreferencesUseCase`) **solo
después de que el POST a `/suscripciones` tuviera éxito** — si ese POST
fallaba o hacía timeout, el método hacía `return` antes de llegar al
guardado local:

```dart
// ANTES
final result = await _subscribeUseCase(...);       // POST /suscripciones
final failed = result.fold(
  (f) { emit(NotificationSubscriptionFailure(...)); return true; },
  (_) => false,
);
if (failed) return;                                  // <- nunca llega a guardar local
await _savePreferencesUseCase(newPrefs);
emit(NotificationSubscriptionLoaded(preferences: newPrefs));
```

El POST corre sobre el `Dio` compartido registrado en `_initCore()`
(`lib/core/di/injection_container.dart`), con `connectTimeout:
ApiEndpoints.connectTimeoutMs` = **15000 ms**. Con el microservicio de
notificaciones (`3.218.172.128:8100`) caído o inalcanzable, Dio lanza
`DioExceptionType.connectionTimeout` a los 15 s, el usecase devuelve
`Left(failure)`, y el usuario ve el botón "Guardar" congelado esos 15 s y
termina en un estado de error — **sin que la preferencia se haya guardado
localmente ni una sola vez**, aunque esa preferencia (el `estado`) es
exactamente lo que alimenta el banner de alerta epidemiológica de Inicio
(feature de clustering, que sí depende de que este guardado local funcione).

## 2. Revisión completa del feature (PASO 2)

- **Mismo patrón en `_onUnsubscribeRequested`** (desactivar alertas): el
  guardado local de `enabled: false` también estaba gateado detrás de
  `DELETE /suscripciones/yo`. **Corregido en este sprint**, con el mismo
  criterio que la suscripción (razón: es el mismo bug, en el mismo archivo,
  con el mismo impacto para el usuario).
- **Re-suscripción automática en login/logout** (`lib/main.dart`,
  `_onLoggedIn`/`_onLoggedOut`, disparada desde un `BlocListener<AuthBloc,
  AuthState>`) y **re-suscripción en refresh de token FCM**
  (`PushNotificationService._handleTokenRefresh`): ambas ya estaban bien
  aisladas — corren en segundo plano sin ser esperadas por ningún widget, y
  la de login/logout ya tiene su propio `try/catch` con comentario explícito
  ("Nunca bloquea ni rompe el flujo de login/logout"). No bloquean la UI ni
  presentan el bug del timeout. Sí quedó un hueco menor (ninguna de las dos
  actualizaba `pushSyncPending` tras una re-suscripción exitosa) — cerrado
  como seguimiento, ver [sección 6](#6-seguimiento---cierre-de-pendientes).
- **`NotificationService` (recordatorios locales de Agenda/Tratamiento)**:
  sin llamadas de red, no aplica.
- **`PushNotificationService` — historial de mensajes FCM
  (`_saveMessage`/`_handleForegroundMessage`)**: solo escribe en Hive local,
  sin llamadas al microservicio externo. No aplica.
- No se encontró ningún otro punto donde una acción local dependiera de que
  el microservicio de notificaciones respondiera a tiempo.

## 3. Qué se cambió para desacoplar

**`notification_preferences_entity.dart`** — se agregó
`pushSyncPending` (bool, default `false`), mismo patrón que
`AgendaActivityEntity.isPendingSync`: `true` cuando la preferencia ya se
guardó localmente pero la suscripción/cancelación push remota todavía no se
confirmó. Se propagó su (de)serialización en
`notification_history_repository_impl.dart` (`push_sync_pending` en el JSON
local).

**`notification_subscription_bloc.dart`** — reordenado en ambos manejadores:

1. Guarda localmente primero (`_savePreferencesUseCase`), con
   `pushSyncPending: true`.
2. Si el guardado local falla (poco probable — es Hive), ahí sí se emite
   `NotificationSubscriptionFailure` (es un fallo real que el usuario debe
   conocer).
3. Si el guardado local tuvo éxito, se emite `NotificationSubscriptionLoaded`
   de inmediato — **esta es la confirmación que ve el usuario, y ya no
   depende del POST/DELETE remoto**.
4. Recién después se intenta la llamada remota (`_subscribeUseCase` /
   `_cancelUseCase`). Si falla o tarda, solo se loguea (`debugPrint` en
   modo debug) — nunca revierte ni sobreescribe la confirmación ya
   mostrada. Si tiene éxito, se vuelve a guardar localmente con
   `pushSyncPending: false` y se emite un `Loaded` actualizado (con un
   guard `_prefsOf(state) == newPrefs` para no pisar un cambio más
   reciente del usuario).

También se hizo inyectable `getFcmToken` en el constructor del Bloc
(default: `FirebaseMessaging.instance.getToken`) — únicamente para poder
testear el flujo sin depender del plugin real de Firebase en `flutter_test`;
el comportamiento en producción no cambia.

**`notification_settings_page.dart`** — se agregó una leyenda pequeña ("Guardado
en el dispositivo. Sincronizando la suscripción push con el servidor…"),
visible solo cuando `enabled && pushSyncPending`, para que la sincronización
pendiente sea visible sin bloquear nada.

No se tocó el endpoint `/suscripciones` ni su contrato — el fix es
enteramente de manejo de la app ante su fallo/timeout.

## 4. `flutter analyze` / `flutter test`

| | Antes de este fix | Después |
|---|---|---|
| `flutter analyze` | 3 issues (`info`, preexistentes) | **Mismos 3 issues**, cero nuevos |
| `flutter test` | 27/27 pasan (20 base + 7 de clustering) | **30/30 pasan** (+3 tests nuevos del Bloc de notificaciones) |

Tests nuevos en `test/features/notifications/notification_subscription_bloc_test.dart`:
- Guardar con el POST fallando/tardando (200 ms simulado) → confirmación
  local inmediata, sin esperar el remoto, sin emitir `Failure`.
- Guardar con el POST exitoso → confirmación inmediata + actualización en
  segundo plano de `pushSyncPending` a `false`.
- Desactivar con el DELETE fallando → mismo comportamiento simétrico.

## 5. Confirmación — nada más se vio afectado

- **Clustering (mapa epidemiológico / banner de Inicio):** sin cambios en
  `lib/features/clustering/`. Sus 7 tests (`clustering_repository_impl_test.dart`)
  siguen pasando sin modificación. El banner sigue leyendo
  `NotificationPreferencesEntity.estado` exactamente igual — el campo nuevo
  `pushSyncPending` no afecta esa lectura (default `false`, no usado por el
  banner).
- **Diagnóstico, Payments, Agenda:** `git diff --stat` contra
  `lib/features/agricultor/diagnosis/`, `lib/features/subscription/`,
  `lib/features/aprendiz/agenda/` y `lib/features/aprendiz/diagnostico/`
  devuelve vacío — ningún archivo de esos módulos fue tocado en este fix.

## 6. Seguimiento — cierre de pendientes

Tras el fix original quedaron dos huecos documentados, ambos cerrados en
esta misma vuelta.

### 6.1 Auto-sincronización de `pushSyncPending`

**Problema:** los dos puntos de reconciliación en segundo plano
(re-suscripción al iniciar sesión y al refrescar el token FCM) reintentaban
el POST remoto, pero nunca volvían a guardar la preferencia localmente —
si ese reintento tenía éxito, `pushSyncPending` se quedaba en `true` para
siempre, aunque la suscripción ya estuviera sincronizada. La leyenda
"Sincronizando…" en Ajustes hubiera quedado mostrada indefinidamente.

**Archivos modificados:**

- `lib/core/services/push_notification_service.dart` — se agregó
  `SaveNotificationPreferencesUseCase` como dependencia del constructor
  (`_savePreferencesUseCase`). En `_handleTokenRefresh`, si
  `_subscribeUseCase(...)` devuelve `Right` (éxito), se vuelve a guardar la
  preferencia con `prefs.copyWith(pushSyncPending: false)`.
- `lib/main.dart` — se pasó `savePreferencesUseCase: sl()` a la
  instanciación de `PushNotificationService` (ya no requirió tocar
  `injection_container.dart`: `SaveNotificationPreferencesUseCase` ya
  estaba registrado ahí desde el fix original). En `_onLoggedIn`, si
  `SubscribeToAlertsUseCase(...)` devuelve `Right`, se llama a
  `sl<SaveNotificationPreferencesUseCase>()(prefs.copyWith(pushSyncPending:
  false))`. `_onLoggedOut` no se tocó (no usa `pushSyncPending`: al cerrar
  sesión la preferencia local ya se guardó como `enabled: false` desde
  Ajustes, si el usuario la desactivó ahí).

No se modificó nada más de esos dos archivos (mismo criterio de riesgo
acotado del fix original).

### 6.2 Test explícito de compatibilidad hacia atrás

**Archivo nuevo:** `test/features/notifications/notification_history_repository_impl_test.dart`.

Prueba `NotificationHistoryRepositoryImpl.getPreferences()` directamente
(no a través del Bloc) con un fake de `NotificationLocalDataSource` que
devuelve el `Map` crudo exacto que habría quedado guardado en Hive **antes**
de que existiera este campo:

```dart
{'enabled': true, 'estado': 'Chiapas', 'cultivos': ['maíz', 'café']}
// sin 'push_sync_pending'
```

Confirma que se lee como `pushSyncPending: false` (no revienta ni deja el
campo nulo) y que `enabled`/`estado`/`cultivos` se leen intactos. Un segundo
caso confirma que un JSON nuevo con `'push_sync_pending': true` sí respeta
ese valor.

### 6.3 `flutter analyze` / `flutter test` (tras cerrar los dos pendientes)

| | Antes de este cierre | Después |
|---|---|---|
| `flutter analyze` | 3 issues (`info`, preexistentes) | **Mismos 3 issues**, cero nuevos |
| `flutter test` | 30/30 pasan | **32/32 pasan** (+2 tests nuevos de compatibilidad hacia atrás) |

`git status`/`git diff --stat` confirman que en esta vuelta solo se
modificaron `lib/core/services/push_notification_service.dart` y
`lib/main.dart` (más los dos archivos de test nuevos) —
`lib/features/clustering/`, `lib/features/agricultor/diagnosis/`,
`lib/features/subscription/`, `lib/features/aprendiz/agenda/` y
`lib/features/aprendiz/diagnostico/` siguen sin ningún cambio.
