import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/crop_activity_entity.dart';
import '../repositories/crop_plan_repository.dart';

class GetDueInspectionActivityUseCase implements UseCase<CropActivityEntity?, NoParams> {
  final CropPlanRepository repository;

  GetDueInspectionActivityUseCase(this.repository);

  @override
  Future<Either<Failure, CropActivityEntity?>> call(NoParams params) async {
    final result = await repository.getSavedCropPlan();
    
    return result.fold(
      (failure) => Left(failure),
      (plan) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        try {
          final dueActivity = plan.activities.firstWhere((a) {
            if (a.status != ActivityStatus.pending) return false;
            
            final activityDate = DateTime(a.scheduledDate.year, a.scheduledDate.month, a.scheduledDate.day);
            
            // Inspección si el título contiene la palabra
            final isInspection = a.title.toLowerCase().contains('inspección') || 
                               a.title.toLowerCase().contains('inspeccion') ||
                               a.title.toLowerCase().contains('diagnóstico') ||
                               a.title.toLowerCase().contains('diagnostico');
            
            // Está vencida o programada para hoy
            final isDue = activityDate.isBefore(today) || activityDate.isAtSameMomentAs(today);
            
            return isInspection && isDue;
          });
          return Right(dueActivity);
        } catch (e) {
          return const Right(null);
        }
      },
    );
  }
}
