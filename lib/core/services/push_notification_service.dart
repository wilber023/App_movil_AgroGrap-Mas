import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/notifications/domain/usecases/notification_preferences_usecases.dart';
import '../../features/notifications/domain/usecases/save_notification_usecase.dart';
import '../../features/notifications/domain/usecases/subscribe_to_alerts_usecase.dart';
import '../../features/notifications/data/models/push_notification_entry_model.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../usecases/usecase.dart';

/// Servicio de notificaciones PUSH (FCM) -- distinto y sin relacion con
/// `NotificationService` (que solo maneja recordatorios locales de
/// Agenda/Tratamiento). Usa su propio canal de Android para no interferir
/// con ese servicio.
///
/// Responsabilidades: pedir permiso, escuchar refresco de token (re-suscribe
/// si ya habia una preferencia guardada), mostrar el push cuando llega en
/// foreground (Android no lo muestra solo si la app esta abierta), guardar
/// cada mensaje recibido en el historial local, y navegar al historial
/// cuando el usuario toca una notificacion (background o terminated).
class PushNotificationService {
  final SaveNotificationUseCase _saveNotificationUseCase;
  final GetNotificationPreferencesUseCase _getPreferencesUseCase;
  final SaveNotificationPreferencesUseCase _savePreferencesUseCase;
  final SubscribeToAlertsUseCase _subscribeUseCase;
  final GlobalKey<NavigatorState> _navigatorKey;

  PushNotificationService({
    required SaveNotificationUseCase saveNotificationUseCase,
    required GetNotificationPreferencesUseCase getPreferencesUseCase,
    required SaveNotificationPreferencesUseCase savePreferencesUseCase,
    required SubscribeToAlertsUseCase subscribeUseCase,
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _saveNotificationUseCase = saveNotificationUseCase,
        _getPreferencesUseCase = getPreferencesUseCase,
        _savePreferencesUseCase = savePreferencesUseCase,
        _subscribeUseCase = subscribeUseCase,
        _navigatorKey = navigatorKey;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'fcm_push_alerts';
  static const String _channelName = 'Alertas fitosanitarias';
  static const String _channelDescription =
      'Notificaciones push de alertas fitosanitarias por estado/cultivo';

  /// Pide permiso, obtiene listo el canal local y engancha los listeners de
  /// FCM. Debe llamarse una unica vez, antes de `runApp` (Android-only, ver
  /// `main.dart`).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings: settings);

    try {
      await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] requestPermission falló: $e');
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    FirebaseMessaging.instance.onTokenRefresh.listen(_handleTokenRefresh);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _saveMessage(initialMessage);
      _openHistory();
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _saveMessage(message);

    final notification = message.notification;
    if (notification == null) return;

    await _plugin.show(
      id: message.hashCode & 0x7fffffff,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    await _saveMessage(message);
    _openHistory();
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    final prefsResult = await _getPreferencesUseCase(const NoParams());
    prefsResult.fold(
      (_) {},
      (prefs) async {
        if (!prefs.enabled || prefs.estado.isEmpty) return;
        final result = await _subscribeUseCase(SubscribeParams(
          fcmToken: newToken,
          estado: prefs.estado,
          cultivos: prefs.cultivos,
        ));
        // Re-suscripcion exitosa en segundo plano: refleja que ya no hay
        // nada pendiente de sincronizar (ver notificaciones_fix.md).
        if (result.isRight()) {
          await _savePreferencesUseCase(prefs.copyWith(pushSyncPending: false));
        }
      },
    );
  }

  Future<void> _saveMessage(RemoteMessage message) async {
    final entry = PushNotificationEntryModel.fromRemoteMessage(message);
    await _saveNotificationUseCase(entry);
  }

  void _openHistory() {
    _navigatorKey.currentState?.push(NotificationsPage.route());
  }
}
