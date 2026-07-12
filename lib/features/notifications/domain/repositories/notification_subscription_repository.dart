import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_subscription_entity.dart';

abstract class NotificationSubscriptionRepository {
  /// Crea o actualiza (idempotente) la suscripcion del usuario actual.
  Future<Either<Failure, NotificationSubscriptionEntity>> subscribe({
    required String fcmToken,
    required String estado,
    List<String>? cultivos,
  });

  /// Consulta la suscripcion actual. `null` cuando el usuario no tiene
  /// ninguna (equivalente al 404 documentado, no se trata como error).
  Future<Either<Failure, NotificationSubscriptionEntity?>> getMySubscription();

  /// Cancela la suscripcion activa.
  Future<Either<Failure, void>> cancelSubscription();
}
