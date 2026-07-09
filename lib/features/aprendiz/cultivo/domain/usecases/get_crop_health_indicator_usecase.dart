import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/crop_health_entity.dart';
import '../repositories/crop_plan_repository.dart';

class GetCropHealthIndicatorUseCase implements UseCase<CropHealthEntity, NoParams> {
  final CropPlanRepository repository;

  GetCropHealthIndicatorUseCase(this.repository);

  @override
  Future<Either<Failure, CropHealthEntity>> call(NoParams params) {
    return repository.getCropHealthIndicator();
  }
}
