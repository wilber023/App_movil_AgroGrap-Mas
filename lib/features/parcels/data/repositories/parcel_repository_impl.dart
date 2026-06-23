import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cultivo_entity.dart';
import '../../domain/entities/parcel_entity.dart';
import '../../domain/repositories/parcel_repository.dart';
import '../datasources/cultivos_remote_datasource.dart';

class ParcelRepositoryImpl implements ParcelRepository {
  final CultivosRemoteDataSource remoteDataSource;

  const ParcelRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ParcelEntity>>> getParcels() async {
    try {
      final selecciones = await remoteDataSource.getMisSelecciones();
      return Right(selecciones);
    } on ServerException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(ServerFailure(message: 'Error al cargar parcelas.', statusCode: null));
    }
  }

  @override
  Future<Either<Failure, ParcelEntity>> getParcelDetail(int seleccionId) async {
    try {
      final selecciones = await remoteDataSource.getMisSelecciones();
      final match = selecciones.where((s) => s.seleccionId == seleccionId).toList();
      if (match.isEmpty) {
        return const Left(ServerFailure(message: 'Parcela no encontrada.', statusCode: 404));
      }
      return Right(match.first);
    } on ServerException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(ServerFailure(message: 'Error al obtener detalle.', statusCode: null));
    }
  }

  @override
  Future<Either<Failure, ParcelEntity>> addParcel(AddParcelParams params) async {
    try {
      final seleccion = await remoteDataSource.crearSeleccion(params);
      return Right(seleccion);
    } on ServerException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(ServerFailure(message: 'Error al registrar la parcela.', statusCode: null));
    }
  }

  @override
  Future<Either<Failure, void>> deleteParcel(int seleccionId) async {
    try {
      await remoteDataSource.eliminarSeleccion(seleccionId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(ServerFailure(message: 'Error al eliminar la parcela.', statusCode: null));
    }
  }

  @override
  Future<Either<Failure, List<CultivoEntity>>> getCultivoCatalog() async {
    try {
      final cultivos = await remoteDataSource.getCatalog();
      return Right(cultivos);
    } on ServerException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(ServerFailure(message: 'Error al cargar el catálogo.', statusCode: null));
    }
  }

  Failure _map(ServerException e) {
    if (e.statusCode == 401) {
      return AuthFailure(message: e.message, statusCode: e.statusCode);
    }
    return ServerFailure(message: e.message, statusCode: e.statusCode);
  }
}
