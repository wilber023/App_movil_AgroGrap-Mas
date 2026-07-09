import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/crop_plan_entity.dart';
import '../entities/crop_health_entity.dart';
import '../entities/crop_activity_entity.dart';
import '../entities/crop_practice_location.dart';

abstract class CropPlanRepository {
  Future<Either<Failure, CropPlanEntity>> getSavedCropPlan();
  Future<Either<Failure, CropPlanEntity>> registerCropPlan({
    required String cropName,
    required DateTime startDate,
    required CropPracticeLocation practiceLocation,
  });
  Future<Either<Failure, CropHealthEntity>> getCropHealthIndicator();
  Future<Either<Failure, CropActivityEntity>> completeActivity(String activityId);
  Future<Either<Failure, CropActivityEntity>> postponeActivity(String activityId, String reason);
  Future<Either<Failure, CropActivityEntity?>> getDueInspectionActivity();
  Future<Either<Failure, Unit>> addActivitiesToPlan(List<CropActivityEntity> activities);
}
