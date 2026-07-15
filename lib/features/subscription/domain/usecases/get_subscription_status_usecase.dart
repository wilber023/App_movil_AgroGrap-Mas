import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptionStatusUseCase implements UseCase<SubscriptionEntity?, NoParams> {
  final SubscriptionRepository repository;
  const GetSubscriptionStatusUseCase(this.repository);

  @override
  Future<Either<Failure, SubscriptionEntity?>> call(NoParams params) {
    if (kDebugMode) {
      debugPrint('[SUB-TRACE] 4) GetSubscriptionStatusUseCase.call -- llamando al Repository');
    }
    return repository.getSubscription();
  }
}
