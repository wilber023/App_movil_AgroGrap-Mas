import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/crop_plan_entity.dart';
import '../repositories/crop_plan_repository.dart';

class RegisterCropPlanUseCase implements UseCase<CropPlanEntity, RegisterCropPlanParams> {
  final CropPlanRepository repository;

  RegisterCropPlanUseCase(this.repository);

  @override
  Future<Either<Failure, CropPlanEntity>> call(RegisterCropPlanParams params) {
    return repository.registerCropPlan(params.cropName, params.startDate);
  }
}

class RegisterCropPlanParams extends Equatable {
  final String cropName;
  final DateTime startDate;

  const RegisterCropPlanParams({required this.cropName, required this.startDate});

  @override
  List<Object?> get props => [cropName, startDate];
}
