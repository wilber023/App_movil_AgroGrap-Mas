import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/subscribe_result_entity.dart';
import '../entities/subscription_entity.dart';

abstract class SubscriptionRepository {
  /// Crea la suscripcion en PayPal. Devuelve la URL donde el usuario aprueba.
  Future<Either<Failure, SubscribeResultEntity>> subscribe({required String plan});

  /// Consulta el estado actual. `null` cuando el usuario no tiene suscripcion
  /// (equivalente al 404 documentado, no se trata como error).
  Future<Either<Failure, SubscriptionEntity?>> getSubscription();

  /// Cancela la suscripcion activa.
  Future<Either<Failure, void>> cancelSubscription();
}
