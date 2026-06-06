// =============================================================================
// Feature: Auth -- Implementacion del Repositorio
// =============================================================================
// Capa: Data
// Regla: Implementa el contrato de dominio [AuthRepository].
//        Coordina entre RemoteDataSource y LocalDataSource.
//        Convierte excepciones (ServerException, CacheException) en
//        Failures (ServerFailure, CacheFailure, NetworkFailure).
//        Verifica conectividad antes de llamar al backend.
// =============================================================================

import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Implementacion concreta de [AuthRepository].
///
/// Estrategia Offline-First:
///   1. Si hay red: intenta primero con el backend, cachea el resultado.
///   2. Si no hay red: retorna datos cacheados si existen.
///   3. Si no hay red ni cache: retorna [NetworkFailure].
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      return _remoteLoginAndCache(username: username, password: password);
    } else {
      // En modo offline, se intenta recuperar la sesion local.
      return _getLocalUser();
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String fullName,
    required String username,
    required String password,
    String? email,
    String? phone,
  }) async {
    if (await networkInfo.isConnected) {
      return _remoteRegisterAndCache(
        fullName: fullName,
        username: username,
        password: password,
        email: email,
        phone: phone,
      );
    } else {
      // Registro offline: crea usuario local marcado como isLocalOnly.
      return _registerOffline(
        fullName: fullName,
        username: username,
        password: password,
        email: email,
        phone: phone,
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    return _getLocalUser();
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Intentar cerrar sesion en el servidor si hay red.
      if (await networkInfo.isConnected) {
        try {
          final cachedUser = await localDataSource.getLastUser();
          if (cachedUser.accessToken != null) {
            await remoteDataSource.logout(
              accessToken: cachedUser.accessToken!,
            );
          }
        } on ServerException {
          // Si falla el logout remoto, igual limpiamos el cache local.
        } on CacheException {
          // Si no hay usuario cacheado, no hay nada que invalidar remotamente.
        }
      }

      // Siempre limpiar el cache local.
      await localDataSource.clearCache();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> refreshSession() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final cachedUser = await localDataSource.getLastUser();

      if (cachedUser.refreshToken == null) {
        return const Left(
          AuthFailure(message: 'No hay token de refresco disponible.'),
        );
      }

      final refreshedUser = await remoteDataSource.refreshToken(
        refreshToken: cachedUser.refreshToken!,
      );

      await localDataSource.cacheUser(refreshedUser);
      return Right(refreshedUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  // ---------------------------------------------------------------------------
  // Metodos privados
  // ---------------------------------------------------------------------------

  /// Ejecuta login remoto y cachea el resultado localmente.
  Future<Either<Failure, UserEntity>> _remoteLoginAndCache({
    required String username,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.login(
        username: username,
        password: password,
      );
      await localDataSource.cacheUser(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  /// Ejecuta registro remoto y cachea el resultado localmente.
  Future<Either<Failure, UserEntity>> _remoteRegisterAndCache({
    required String fullName,
    required String username,
    required String password,
    String? email,
    String? phone,
  }) async {
    try {
      final user = await remoteDataSource.register(
        fullName: fullName,
        username: username,
        password: password,
        email: email,
        phone: phone,
      );
      await localDataSource.cacheUser(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  /// Crea un usuario local en modo offline.
  Future<Either<Failure, UserEntity>> _registerOffline({
    required String fullName,
    required String username,
    required String password,
    String? email,
    String? phone,
  }) async {
    try {
      final localUser = UserModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName,
        username: username,
        email: email,
        phone: phone,
        isLocalOnly: true,
        createdAt: DateTime.now(),
      );

      await localDataSource.cacheUser(localUser);
      return Right(localUser);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  /// Recupera el usuario desde el cache local.
  Future<Either<Failure, UserEntity>> _getLocalUser() async {
    try {
      final cachedUser = await localDataSource.getLastUser();
      return Right(cachedUser);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}
