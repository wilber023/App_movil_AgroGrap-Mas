import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/crop_activity_entity.dart';
import '../repositories/crop_plan_repository.dart';
import 'complete_activity_usecase.dart';


class AcceptGuidedActionParams {
  final String activityId;
  const AcceptGuidedActionParams({required this.activityId});
}

class AcceptGuidedActionUseCase implements UseCase<List<CropActivityEntity>, AcceptGuidedActionParams> {
  final CompleteActivityUseCase completeActivityUseCase;
  final CropPlanRepository cropPlanRepository;

  AcceptGuidedActionUseCase({
    required this.completeActivityUseCase,
    required this.cropPlanRepository,
  });

  @override
  Future<Either<Failure, List<CropActivityEntity>>> call(AcceptGuidedActionParams params) async {
    // 1. Completar la actividad actual
    final completeResult = await completeActivityUseCase(
      CompleteActivityParams(activityId: params.activityId),
    );

    return completeResult.fold(
      (failure) => Left(failure),
      (completedActivity) async {
        // 2. Generar 3 nuevas actividades
        final now = DateTime.now();
        final idPrefix = now.millisecondsSinceEpoch.toString();
        
        // Mantener la lógica simple del UseCase con la fecha real del sistema
        final newActivities = [
          CropActivityEntity(
            id: '${idPrefix}_1',
            weekNumber: completedActivity.weekNumber, // Misma semana
            title: 'Primera aplicación de fungicida',
            description: 'Aplicar tratamiento recomendado en la zona afectada',
            scheduledDate: now,
            status: ActivityStatus.pending,
            isPendingSync: true,
          ),
          CropActivityEntity(
            id: '${idPrefix}_2',
            weekNumber: completedActivity.weekNumber + 1,
            title: 'Seguimiento y revisión',
            description: 'Revisar si el tratamiento detuvo el avance de la enfermedad',
            scheduledDate: now.add(const Duration(days: 7)),
            status: ActivityStatus.pending,
            isPendingSync: true,
          ),
          CropActivityEntity(
            id: '${idPrefix}_3',
            weekNumber: completedActivity.weekNumber + 2,
            title: 'Nueva inspección con foto',
            description: 'Toma una nueva foto para confirmar la sanidad de la planta',
            scheduledDate: now.add(const Duration(days: 14)),
            status: ActivityStatus.pending,
            isPendingSync: true,
          ),
        ];

        // 3. Persistirlas
        final saveResult = await cropPlanRepository.addActivitiesToPlan(newActivities);
        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(newActivities),
        );
      },
    );
  }
}
