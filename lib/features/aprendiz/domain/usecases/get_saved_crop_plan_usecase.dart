import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/crop_plan_entity.dart';
import '../repositories/crop_plan_repository.dart';

class GetSavedCropPlanUseCase implements UseCase<CropPlanEntity, NoParams> {
  final CropPlanRepository repository;

  GetSavedCropPlanUseCase(this.repository);

  @override
  Future<Either<Failure, CropPlanEntity>> call(NoParams params) {
    return repository.getSavedCropPlan();
  }
}
