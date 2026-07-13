import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/alerta_epidemiologica_entity.dart';
import '../../domain/entities/estado_resumen_entity.dart';
import '../../domain/repositories/clustering_repository.dart';
import '../datasources/clustering_remote_datasource.dart';

class ClusteringRepositoryImpl implements ClusteringRepository {
  final ClusteringRemoteDataSource remoteDataSource;

  const ClusteringRepositoryImpl({required this.remoteDataSource});

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

  Failure _map(ServerException e) {
    if (e.statusCode == 401) {
      return AuthFailure(message: e.message, statusCode: e.statusCode);
    }
    return ServerFailure(message: e.message, statusCode: e.statusCode);
  }
}
