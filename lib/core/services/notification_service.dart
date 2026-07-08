import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Servicio de notificaciones locales (recordatorios de la Agenda).
///
/// Inicializacion perezosa: se inicializa solo la primera vez que se
/// programa/cancela/pide permiso, para no requerir tocar `main.dart`.
///
/// Nota sobre zonas horarias: no se agrega un plugin de deteccion de zona
/// horaria del dispositivo. En su lugar, `tz.local` se deja en su valor por
/// defecto (UTC) y las fechas locales se convierten con
/// `TZDateTime.from(fecha, tz.local)`, que preserva el instante absoluto
/// (epoch) de la fecha original sin importar la zona de representacion. El
/// recordatorio se dispara igual en el momento real correcto.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'agenda_reminders';
  static const String _channelName = 'Recordatorios de agenda';
  static const String _channelDescription =
      'Avisos de tareas y tratamientos programados en la Agenda';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Pide permiso de notificaciones (Android 13+ / iOS). Debe llamarse en
  /// respuesta a una accion explicita del usuario (ej. activar el switch de
  /// recordatorios), nunca automaticamente al abrir la app.
  Future<bool> requestPermission() async {
    await _ensureInitialized();

    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Si la plataforma no expone ese resolver (ej. ya se concedio antes o no
    // aplica), se asume concedido para no bloquear el flujo.
    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  /// Programa (reemplazando cualquier anterior con el mismo [id]) un
  /// recordatorio para [whenLocal]. Si esa fecha ya paso, no hace nada.
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime whenLocal,
  }) async {
    await _ensureInitialized();
    if (whenLocal.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(whenLocal, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) async {
    await _ensureInitialized();
    await _plugin.cancel(id: id);
  }

  /// Id estable de notificacion a partir del tratamiento y el paso, para
  /// poder cancelar/reemplazar el mismo recordatorio de forma idempotente
  /// sin tener que guardar el id en Hive.
  static int stableId(String treatmentId, String stepId) {
    return ('$treatmentId|$stepId').hashCode & 0x7fffffff;
  }
}
