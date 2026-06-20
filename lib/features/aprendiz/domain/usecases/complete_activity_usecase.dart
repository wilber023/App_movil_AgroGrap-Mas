import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/crop_activity_entity.dart';
import '../repositories/crop_plan_repository.dart';

class CompleteActivityUseCase implements UseCase<CropActivityEntity, CompleteActivityParams> {
  final CropPlanRepository repository;

  CompleteActivityUseCase(this.repository);

  @override
  Future<Either<Failure, CropActivityEntity>> call(CompleteActivityParams params) {
    return repository.completeActivity(params.activityId);
  }
}

class CompleteActivityParams extends Equatable {
  final String activityId;
  const CompleteActivityParams({required this.activityId});

  @override
  List<Object?> get props => [activityId];
}
