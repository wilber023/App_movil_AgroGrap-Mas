import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notification_subscription_entity.dart';
import '../repositories/notification_subscription_repository.dart';

class SubscribeParams {
  final String fcmToken;
  final String estado;
  final List<String>? cultivos;

  const SubscribeParams({
    required this.fcmToken,
    required this.estado,
    this.cultivos,
  });
}

class SubscribeToAlertsUseCase implements UseCase<NotificationSubscriptionEntity, SubscribeParams> {
  final NotificationSubscriptionRepository repository;
  const SubscribeToAlertsUseCase(this.repository);

  @override
  Future<Either<Failure, NotificationSubscriptionEntity>> call(SubscribeParams params) {
    return repository.subscribe(
      fcmToken: params.fcmToken,
      estado: params.estado,
      cultivos: params.cultivos,
    );
  }
}
