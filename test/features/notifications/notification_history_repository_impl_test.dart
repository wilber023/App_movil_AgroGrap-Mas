import 'package:flutter_test/flutter_test.dart';

import 'package:agrograp_movil/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:agrograp_movil/features/notifications/data/models/push_notification_entry_model.dart';
import 'package:agrograp_movil/features/notifications/data/repositories/notification_history_repository_impl.dart';

/// Fake en memoria de [NotificationLocalDataSource] -- permite devolver
/// exactamente el `Map` crudo que estaría guardado en Hive, incluyendo uno
/// "viejo" sin la clave `push_sync_pending` (agregada después).
class _FakeLocalDataSource implements NotificationLocalDataSource {
  Map<String, dynamic>? preferencesToReturn;

  @override
  Map<String, dynamic>? getPreferences() => preferencesToReturn;

  @override
  Future<void> savePreferences(Map<String, dynamic> prefs) async {
    preferencesToReturn = prefs;
  }

  @override
  List<PushNotificationEntryModel> getHistory() => const [];

  @override
  Future<void> saveReceived(PushNotificationEntryModel entry) async {}
}

void main() {
  late _FakeLocalDataSource local;
  late NotificationHistoryRepositoryImpl repository;

  setUp(() {
    local = _FakeLocalDataSource();
    repository = NotificationHistoryRepositoryImpl(localDataSource: local);
  });

  test(
    'JSON guardado por una version anterior (sin push_sync_pending) -> se '
    'lee con pushSyncPending: false por defecto, sin romper el resto de '
    'los campos',
    () async {
      // Tal cual quedaría en Hive antes de que este campo existiera.
      local.preferencesToReturn = {
        'enabled': true,
        'estado': 'Chiapas',
        'cultivos': ['maíz', 'café'],
      };

      final result = await repository.getPreferences();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('no debería fallar'),
        (prefs) {
          expect(prefs.enabled, isTrue);
          expect(prefs.estado, 'Chiapas');
          expect(prefs.cultivos, ['maíz', 'café']);
          expect(prefs.pushSyncPending, isFalse);
        },
      );
    },
  );

  test(
    'JSON nuevo con push_sync_pending: true -> se respeta el valor guardado',
    () async {
      local.preferencesToReturn = {
        'enabled': true,
        'estado': 'Sinaloa',
        'cultivos': [],
        'push_sync_pending': true,
      };

      final result = await repository.getPreferences();

      result.fold(
        (_) => fail('no debería fallar'),
        (prefs) => expect(prefs.pushSyncPending, isTrue),
      );
    },
  );
}
