import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/crop_plan_repository.dart';

class GetCropPlanProgressUseCase implements UseCase<double, NoParams> {
  final CropPlanRepository repository;

  GetCropPlanProgressUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(NoParams params) async {
    final result = await repository.getSavedCropPlan();
    return result.fold(
      (failure) => Left(failure),
      (plan) => Right(plan.progressPercentage),
    );
  }
}
