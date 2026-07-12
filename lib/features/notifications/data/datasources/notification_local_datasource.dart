import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../models/push_notification_entry_model.dart';

abstract interface class NotificationLocalDataSource {
  List<PushNotificationEntryModel> getHistory();
  Future<void> saveReceived(PushNotificationEntryModel entry);

  Map<String, dynamic>? getPreferences();
  Future<void> savePreferences(Map<String, dynamic> prefs);
}

/// Historial local de notificaciones (`Box&lt;String&gt;`, valores JSON-encoded --
/// mismo patron que AuthLocalDataSource/TreatmentLocalDataSource).
///
/// Cada notificacion se guarda con `put(entry.id, ...)`: si el mismo mensaje
/// llega por mas de un listener (foreground/background/tap), la segunda
/// escritura simplemente sobreescribe la primera con el mismo contenido --
/// dedup gratis, sin necesidad de escanear el historial existente.
///
/// La preferencia de suscripcion (estado/cultivos/enabled) se guarda bajo
/// una clave fija separada (`_prefsKey`), en la MISMA box.
class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final Box<String> box;

  static const _prefsKey = '_prefs';

  const NotificationLocalDataSourceImpl({required this.box});

  @override
  List<PushNotificationEntryModel> getHistory() {
    try {
      final entries = <PushNotificationEntryModel>[];
      for (final key in box.keys) {
        if (key == _prefsKey) continue;
        final raw = box.get(key);
        if (raw == null) continue;
        try {
          entries.add(PushNotificationEntryModel.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          ));
        } catch (_) {
          continue;
        }
      }
      entries.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      return entries;
    } catch (_) {
      throw const CacheException(message: 'No se pudo leer el historial de notificaciones.');
    }
  }

  @override
  Future<void> saveReceived(PushNotificationEntryModel entry) async {
    try {
      await box.put(entry.id, jsonEncode(entry.toJson()));
    } catch (_) {
      throw const CacheException(message: 'No se pudo guardar la notificación recibida.');
    }
  }

  @override
  Map<String, dynamic>? getPreferences() {
    final raw = box.get(_prefsKey);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePreferences(Map<String, dynamic> prefs) async {
    try {
      await box.put(_prefsKey, jsonEncode(prefs));
    } catch (_) {
      throw const CacheException(message: 'No se pudo guardar tu preferencia de notificaciones.');
    }
  }
}
