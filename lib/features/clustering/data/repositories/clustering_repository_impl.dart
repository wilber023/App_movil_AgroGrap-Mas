import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/alerta_epidemiologica_entity.dart';
import '../../domain/entities/estado_resumen_entity.dart';
import '../../domain/repositories/clustering_repository.dart';
import '../datasources/clustering_remote_datasource.dart';
import '../datasources/clustering_report_remote_datasource.dart';

class ClusteringRepositoryImpl implements ClusteringRepository {
  final ClusteringRemoteDataSource remoteDataSource;
  final ClusteringReportRemoteDataSource reportRemoteDataSource;

  const ClusteringRepositoryImpl({
    required this.remoteDataSource,
    required this.reportRemoteDataSource,
  });

  @override
  Future<Either<Failure, MapaCampaniasEntity>> getMapaCampanias() async {
    try {
      final mapa = await remoteDataSource.getMapaCampanias();
      return Right(mapa);
    } on ServerException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(
          ServerFailure(message: 'Error al cargar el mapa epidemiológico.', statusCode: null));
    }
  }

  @override
  Future<Either<Failure, AlertaEpidemiologicaEntity>> getAlerta({String? estado}) async {
    try {
      final alerta = await remoteDataSource.getAlerta(estado: estado);
      return Right(alerta);
    } on ServerException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(
          ServerFailure(message: 'Error al cargar la alerta epidemiológica.', statusCode: null));
    }
  }

  @override
  Future<void> enviarReporte({
    required String cultivo,
    required String plaga,
    required String estado,
  }) async {
    try {
      await reportRemoteDataSource.enviarReporte(
        cultivo: cultivo,
        plaga: plaga,
        estado: estado,
      );
      debugPrint('[ClusteringReporte] enviado OK (cultivo=$cultivo, plaga=$plaga, estado=$estado)');
    } catch (e) {
      // Fire-and-forget: el diagnóstico nunca debe depender de este envío.
      debugPrint('[ClusteringReporte] FALLÓ, se descarta silenciosamente: $e');
    }
  }

  Failure _map(ServerException e) {
    if (e.statusCode == 401) {
      return AuthFailure(message: e.message, statusCode: e.statusCode);
    }
    return ServerFailure(message: e.message, statusCode: e.statusCode);
  }
}
