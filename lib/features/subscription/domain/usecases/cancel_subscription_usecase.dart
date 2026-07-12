import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/subscription_repository.dart';

class CancelSubscriptionUseCase implements UseCase<void, NoParams> {
  final SubscriptionRepository repository;
  const CancelSubscriptionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.cancelSubscription();
  }
}
