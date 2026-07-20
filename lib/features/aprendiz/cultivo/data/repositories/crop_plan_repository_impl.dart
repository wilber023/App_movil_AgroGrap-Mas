import 'package:dartz/dartz.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/network_info.dart';
import '../../domain/entities/crop_plan_entity.dart';
import '../../domain/entities/crop_health_entity.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../../domain/entities/crop_practice_location.dart';
import '../../domain/repositories/crop_plan_repository.dart';
import '../datasources/crop_plan_remote_datasource.dart';
import '../datasources/crop_plan_local_datasource.dart';
import '../models/crop_plan_model.dart';
import '../models/crop_activity_model.dart';

class CropPlanRepositoryImpl implements CropPlanRepository {
  final CropPlanRemoteDataSource remoteDataSource;
  final CropPlanLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CropPlanRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, CropPlanEntity>> getSavedCropPlan() async {
    if (await networkInfo.isConnected) {
      try {
        final remotePlan = await remoteDataSource.getSavedCropPlan();
        await localDataSource.cacheCropPlan(remotePlan);
        return Right(remotePlan);
      } catch (e) {
        // Fallback a local
        final localPlan = await localDataSource.getCachedCropPlan();
        if (localPlan != null) {
          return Right(localPlan);
        }
        return Left(_mapException(e));
      }
    } else {
      final localPlan = await localDataSource.getCachedCropPlan();
      if (localPlan != null) {
        return Right(localPlan);
      }
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, CropPlanEntity>> registerCropPlan({
    required String cultivoId,
    required DateTime startDate,
    required CropPracticeLocation practiceLocation,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final remotePlan = await remoteDataSource.registerCropPlan(
        cultivoId: cultivoId,
        startDate: startDate,
        practiceLocation: practiceLocation,
      );
      await localDataSource.cacheCropPlan(remotePlan);
      return Right(remotePlan);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, String>> getSowingPlanText({
    required String cropName,
    required CropPracticeLocation practiceLocation,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final texto = await remoteDataSource.getSowingPlanText(
        cropName: cropName,
        practiceLocation: practiceLocation,
      );
      return Right(texto);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  Failure _mapException(Object e) {
    if (e is ServerException) {
      if (e.statusCode == 401) {
        return AuthFailure(message: e.message, statusCode: e.statusCode);
      }
      return ServerFailure(message: e.message, statusCode: e.statusCode);
    }
    return ServerFailure(message: e.toString());
  }

  @override
  Future<Either<Failure, CropHealthEntity>> getCropHealthIndicator() async {
    if (await networkInfo.isConnected) {
      try {
        final health = await remoteDataSource.getCropHealthIndicator();
        return Right(health);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, CropActivityEntity>> completeActivity(String activityId) async {
    return _updateActivityStatus(activityId, ActivityStatus.completed, null);
  }

  @override
  Future<Either<Failure, CropActivityEntity>> postponeActivity(String activityId, String reason) async {
    return _updateActivityStatus(activityId, ActivityStatus.postponed, reason);
  }

  Future<Either<Failure, CropActivityEntity>> _updateActivityStatus(String activityId, ActivityStatus status, String? reason) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteActivity = await remoteDataSource.updateActivityStatus(activityId, status, reason);
        await localDataSource.cacheActivityUpdate(remoteActivity);
        return Right(remoteActivity);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      final localPlan = await localDataSource.getCachedCropPlan();
      if (localPlan != null) {
        try {
          final targetActivity = localPlan.activities.firstWhere((a) => a.id == activityId);
          final updatedActivity = CropActivityModel.fromEntity(targetActivity.copyWith(
            status: status,
            isPendingSync: true,
          ));
          await localDataSource.cacheActivityUpdate(updatedActivity);
          return Right(updatedActivity);
        } catch (e) {
           return const Left(CacheFailure(message: 'Actividad no encontrada en caché local'));
        }
      }
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, CropActivityEntity?>> getDueInspectionActivity() async {
    // Delegado a GetDueInspectionActivityUseCase según requerimiento de arquitectura,
    // pero la interfaz exige implementarlo aquí también.
    final planResult = await getSavedCropPlan();
    return planResult.fold(
      (failure) => Left(failure),
      (plan) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        try {
          final dueActivity = plan.activities.firstWhere((a) {
            if (a.status != ActivityStatus.pending) return false;
            final activityDate = DateTime(a.scheduledDate.year, a.scheduledDate.month, a.scheduledDate.day);
            final isInspection = a.title.toLowerCase().contains('inspección') || a.title.toLowerCase().contains('inspeccion');
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

  @override
  Future<Either<Failure, Unit>> addActivitiesToPlan(List<CropActivityEntity> newActivities) async {
    final planResult = await getSavedCropPlan();
    return planResult.fold(
      (failure) => Left(failure),
      (plan) async {
        try {
          final updatedActivities = List<CropActivityEntity>.from(plan.activities)..addAll(newActivities);
          final updatedPlan = CropPlanModel(
            id: plan.id,
            userId: plan.userId,
            cropName: plan.cropName,
            startDate: plan.startDate,
            currentStage: plan.currentStage,
            currentWeek: plan.currentWeek,
            progressPercentage: plan.progressPercentage,
            activities: updatedActivities.map((a) => CropActivityModel.fromEntity(a)).toList(),
          );
          await localDataSource.cacheCropPlan(updatedPlan);
          
          if (await networkInfo.isConnected) {
             // Sincronizar aquí si el backend soporta post de actividades
          }
          return const Right(unit);
        } catch (e) {
          return Left(CacheFailure(message: 'Error actualizando el plan local'));
        }
      },
    );
  }
}
