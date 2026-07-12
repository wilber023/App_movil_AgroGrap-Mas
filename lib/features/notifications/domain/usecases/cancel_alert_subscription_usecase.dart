import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notification_subscription_repository.dart';

class CancelAlertSubscriptionUseCase implements UseCase<void, NoParams> {
  final NotificationSubscriptionRepository repository;
  const CancelAlertSubscriptionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.cancelSubscription();
  }
}
