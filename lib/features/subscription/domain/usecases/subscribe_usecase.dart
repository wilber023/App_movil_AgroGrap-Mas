import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/subscribe_result_entity.dart';
import '../repositories/subscription_repository.dart';

class SubscribeParams extends Equatable {
  final String plan; // 'monthly' | 'yearly'
  const SubscribeParams({required this.plan});

  @override
  List<Object?> get props => [plan];
}

class SubscribeUseCase implements UseCase<SubscribeResultEntity, SubscribeParams> {
  final SubscriptionRepository repository;
  const SubscribeUseCase(this.repository);

  @override
  Future<Either<Failure, SubscribeResultEntity>> call(SubscribeParams params) {
    return repository.subscribe(plan: params.plan);
  }
}
