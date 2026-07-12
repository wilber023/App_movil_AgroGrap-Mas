import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_preferences_entity.dart';
import '../entities/push_notification_entry_entity.dart';

abstract class NotificationHistoryRepository {
  /// Historial local de notificaciones recibidas, mas reciente primero.
  Future<Either<Failure, List<PushNotificationEntryEntity>>> getHistory();

  /// Guarda una notificacion recibida (dedup por id -- ver
  /// NotificationLocalDataSource).
  Future<Either<Failure, void>> saveReceived(PushNotificationEntryEntity entry);

  /// Preferencia de suscripcion guardada localmente (estado/cultivos/enabled).
  Future<Either<Failure, NotificationPreferencesEntity>> getPreferences();

  Future<Either<Failure, void>> savePreferences(NotificationPreferencesEntity prefs);
}
