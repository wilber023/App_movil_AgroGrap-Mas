import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/notifications/data/models/push_notification_entry_model.dart';

/// Handler de FCM para mensajes en background/terminated. DEBE ser una
/// funcion top-level (fuera de cualquier clase) y estar marcada con
/// `@pragma('vm:entry-point')`: el motor Flutter la ejecuta en un isolate
/// separado del isolate principal de la app.
///
/// Restriccion real (no evitable): ese isolate NO comparte memoria con el
/// principal -- no tiene acceso al `sl` (GetIt) ya inicializado ni a las Box
/// de Hive ya abiertas ahi. Por eso este handler hace su propia
/// inicializacion minima de Firebase/Hive en vez de depender de
/// `initDependencies()`. Ademas, si la app sigue viva en background (no
/// terminada), el archivo de la Box puede estar bloqueado por el isolate
/// principal -- el try/catch hace ese fallo silencioso y no fatal; en ese
/// caso la notificacion igual queda registrada al abrir la app
/// (`onMessageOpenedApp`/`getInitialMessage`, ver PushNotificationService).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await Hive.initFlutter();
    final box = await Hive.openBox<String>('notifications_box');
    final entry = PushNotificationEntryModel.fromRemoteMessage(message);
    await box.put(entry.id, jsonEncode(entry.toJson()));
    await box.close();
  } catch (_) {
    // Nunca debe tronar este isolate en segundo plano; best-effort silencioso.
  }
}
