import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptionStatusUseCase implements UseCase<SubscriptionEntity?, NoParams> {
  final SubscriptionRepository repository;
  const GetSubscriptionStatusUseCase(this.repository);

  @override
  Future<Either<Failure, SubscriptionEntity?>> call(NoParams params) {
    return repository.getSubscription();
  }
}
