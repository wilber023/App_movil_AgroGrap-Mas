import 'package:dartz/dartz.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/network_info.dart';
import '../../domain/entities/agenda_activity_entity.dart';
import '../../domain/entities/agenda_overview_entity.dart';
import '../../domain/repositories/agenda_repository.dart';
import '../datasources/agenda_local_datasource.dart';
import '../datasources/agenda_remote_datasource.dart';
import '../models/agenda_activity_model.dart';

/// Implementacion generica del modulo Agenda, reutilizada tanto para
/// Agricultor como para Aprendiz -- cada perfil registra su propia
/// instancia (con su propia caja Hive local) fijando [rol], para no
/// duplicar la logica de red/cache/offline-first en dos archivos.
class AgendaRepositoryImpl implements AgendaRepository {
  final AgendaRemoteDataSource remoteDataSource;
  final AgendaLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final String rol;

  AgendaRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.rol,
  });

  @override
  Future<Either<Failure, AgendaOverviewEntity>> generarAgenda({
    required String cultivo,
    String? enfermedad,
    required String tratamiento,
    String? prevencion,
    String? currentStage,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final overview = await remoteDataSource.generar(
        rol,
        GenerarAgendaParams(
          cultivo: cultivo,
          enfermedad: enfermedad,
          tratamiento: tratamiento,
          prevencion: prevencion,
          currentStage: currentStage,
        ),
      );
      await localDataSource.cacheOverview(overview);
      return Right(overview);
    } on ServerException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(ServerFailure(message: 'Error al generar la agenda.', statusCode: null));
    }
  }

  @override
  Future<Either<Failure, AgendaOverviewEntity>> getAgendaOverview() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteOverview = await remoteDataSource.getAgendaOverview(rol);
        await localDataSource.cacheOverview(remoteOverview);
        return Right(remoteOverview);
      } catch (_) {
        final cached = await localDataSource.getCachedOverview();
        return Right(cached);
      }
    }
    final cached = await localDataSource.getCachedOverview();
    return Right(cached);
  }

  @override
  Future<Either<Failure, AgendaActivityEntity>> completeActivity(String activityId) {
    return _updateActivityStatus(activityId, AgendaActivityStatus.completed, null);
  }

  @override
  Future<Either<Failure, AgendaActivityEntity>> postponeActivity(String activityId, String reason) {
    return _updateActivityStatus(activityId, AgendaActivityStatus.postponed, reason);
  }

  Future<Either<Failure, AgendaActivityEntity>> _updateActivityStatus(
    String activityId,
    AgendaActivityStatus status,
    String? reason,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final updated = status == AgendaActivityStatus.completed
            ? await remoteDataSource.completeActivity(rol, activityId)
            : await remoteDataSource.postponeActivity(rol, activityId, reason!);
        final applied = await localDataSource.applyActivityUpdate(updated);
        return Right(applied);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    }

    try {
      final overview = await localDataSource.getCachedOverview();
      final target = overview.activities.firstWhere((a) => a.id == activityId);
      final updated = AgendaActivityModel.fromEntity(
        target.copyWith(status: status, isPendingSync: true),
      );
      final applied = await localDataSource.applyActivityUpdate(updated);
      return Right(applied);
    } catch (_) {
      return const Left(CacheFailure(message: 'Actividad no encontrada en la agenda local'));
    }
  }

  Failure _map(ServerException e) {
    if (e.statusCode == 401) {
      return AuthFailure(message: e.message, statusCode: e.statusCode);
    }
    return ServerFailure(message: e.message, statusCode: e.statusCode);
  }
}
