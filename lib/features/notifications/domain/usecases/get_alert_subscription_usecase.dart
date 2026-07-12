import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notification_subscription_entity.dart';
import '../repositories/notification_subscription_repository.dart';

class GetAlertSubscriptionUseCase implements UseCase<NotificationSubscriptionEntity?, NoParams> {
  final NotificationSubscriptionRepository repository;
  const GetAlertSubscriptionUseCase(this.repository);

  @override
  Future<Either<Failure, NotificationSubscriptionEntity?>> call(NoParams params) {
    return repository.getMySubscription();
  }
}
