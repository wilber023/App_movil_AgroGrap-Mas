import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_preferences_entity.dart';
import '../../domain/entities/push_notification_entry_entity.dart';
import '../../domain/repositories/notification_history_repository.dart';
import '../datasources/notification_local_datasource.dart';
import '../models/push_notification_entry_model.dart';

class NotificationHistoryRepositoryImpl implements NotificationHistoryRepository {
  final NotificationLocalDataSource localDataSource;

  const NotificationHistoryRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<PushNotificationEntryEntity>>> getHistory() async {
    try {
      return Right(localDataSource.getHistory());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (_) {
      return const Left(CacheFailure(message: 'No se pudo leer el historial de notificaciones.'));
    }
  }

  @override
  Future<Either<Failure, void>> saveReceived(PushNotificationEntryEntity entry) async {
    try {
      await localDataSource.saveReceived(
        entry is PushNotificationEntryModel
            ? entry
            : PushNotificationEntryModel(
                id: entry.id,
                title: entry.title,
                body: entry.body,
                estado: entry.estado,
                campania: entry.campania,
                receivedAt: entry.receivedAt,
              ),
      );
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (_) {
      return const Left(CacheFailure(message: 'No se pudo guardar la notificación recibida.'));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferencesEntity>> getPreferences() async {
    try {
      final raw = localDataSource.getPreferences();
      if (raw == null) return const Right(NotificationPreferencesEntity.empty);
      final cultivosRaw = raw['cultivos'];
      return Right(NotificationPreferencesEntity(
        enabled: raw['enabled'] == true,
        estado: raw['estado']?.toString() ?? '',
        cultivos: cultivosRaw is List
            ? cultivosRaw.map((e) => e.toString()).toList()
            : const [],
        pushSyncPending: raw['push_sync_pending'] == true,
      ));
    } catch (_) {
      return const Right(NotificationPreferencesEntity.empty);
    }
  }

  @override
  Future<Either<Failure, void>> savePreferences(NotificationPreferencesEntity prefs) async {
    try {
      await localDataSource.savePreferences({
        'enabled': prefs.enabled,
        'estado': prefs.estado,
        'cultivos': prefs.cultivos,
        'push_sync_pending': prefs.pushSyncPending,
      });
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (_) {
      return const Left(
        CacheFailure(message: 'No se pudo guardar tu preferencia de notificaciones.'),
      );
    }
  }
}
