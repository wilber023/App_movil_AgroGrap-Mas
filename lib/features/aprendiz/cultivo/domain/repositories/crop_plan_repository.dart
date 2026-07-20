import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/crop_plan_entity.dart';
import '../entities/crop_health_entity.dart';
import '../entities/crop_activity_entity.dart';
import '../entities/crop_practice_location.dart';

abstract class CropPlanRepository {
  Future<Either<Failure, CropPlanEntity>> getSavedCropPlan();
  Future<Either<Failure, CropPlanEntity>> registerCropPlan({
    required String cultivoId,
    required DateTime startDate,
    required CropPracticeLocation practiceLocation,
  });
  Future<Either<Failure, CropHealthEntity>> getCropHealthIndicator();

  /// Texto del plan de siembra generado por el backend LLM para el cultivo
  /// de práctica recién registrado (ver README_plan_siembra_aprendiz.md).
  /// Ese texto se usa luego como `tratamiento` al generar la agenda con el
  /// mismo endpoint que ya usa el flujo de diagnóstico.
  Future<Either<Failure, String>> getSowingPlanText({
    required String cropName,
    required CropPracticeLocation practiceLocation,
  });
  Future<Either<Failure, CropActivityEntity>> completeActivity(String activityId);
  Future<Either<Failure, CropActivityEntity>> postponeActivity(String activityId, String reason);
  Future<Either<Failure, CropActivityEntity?>> getDueInspectionActivity();
  Future<Either<Failure, Unit>> addActivitiesToPlan(List<CropActivityEntity> activities);
}
