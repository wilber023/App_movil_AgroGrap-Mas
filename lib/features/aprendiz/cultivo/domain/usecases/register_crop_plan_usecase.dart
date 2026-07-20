import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/crop_plan_entity.dart';
import '../entities/crop_practice_location.dart';
import '../repositories/crop_plan_repository.dart';

class RegisterCropPlanUseCase implements UseCase<CropPlanEntity, RegisterCropPlanParams> {
  final CropPlanRepository repository;

  RegisterCropPlanUseCase(this.repository);

  @override
  Future<Either<Failure, CropPlanEntity>> call(RegisterCropPlanParams params) {
    return repository.registerCropPlan(
      cultivoId: params.cultivoId,
      startDate: params.startDate,
      practiceLocation: params.practiceLocation,
    );
  }
}

class RegisterCropPlanParams extends Equatable {
  final String cultivoId;
  final DateTime startDate;
  final CropPracticeLocation practiceLocation;

  const RegisterCropPlanParams({
    required this.cultivoId,
    required this.startDate,
    required this.practiceLocation,
  });

  @override
  List<Object?> get props => [cultivoId, startDate, practiceLocation];
}
