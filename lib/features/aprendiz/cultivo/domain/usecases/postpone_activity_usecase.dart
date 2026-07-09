import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/crop_activity_entity.dart';
import '../repositories/crop_plan_repository.dart';

class PostponeActivityUseCase implements UseCase<CropActivityEntity, PostponeActivityParams> {
  final CropPlanRepository repository;

  PostponeActivityUseCase(this.repository);

  @override
  Future<Either<Failure, CropActivityEntity>> call(PostponeActivityParams params) {
    return repository.postponeActivity(params.activityId, params.reason);
  }
}

class PostponeActivityParams extends Equatable {
  final String activityId;
  final String reason;
  
  const PostponeActivityParams({required this.activityId, required this.reason});

  @override
  List<Object?> get props => [activityId, reason];
}
