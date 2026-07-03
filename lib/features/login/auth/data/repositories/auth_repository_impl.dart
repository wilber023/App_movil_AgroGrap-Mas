// =============================================================================
// Feature: Auth -- Implementación del Repositorio
// =============================================================================
// Capa: Data
// Coordina entre RemoteDataSource, LocalDataSource y TokenStorage.
// Convierte excepciones en Failures y aplica la estrategia Offline-First.
//
// Escritura dual al autenticar:
//   1. localDataSource.cacheUser()  → sesión completa para Offline-First.
//   2. tokenStorage.saveTokens()    → tokens aislados para el AuthInterceptor.
//
// Esto garantiza que el interceptor siempre lea tokens frescos sin
// depender de la estructura completa de UserModel.
// =============================================================================

import 'package:dartz/dartz.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/network_info.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../domain/entities/profile_type.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final TokenStorage tokenStorage;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.tokenStorage,
  });

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.login(
          username: username,
          password: password,
        );
        await _persistSession(user);
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
      }
    }
    return _getLocalUser();
  }

  // ---------------------------------------------------------------------------
  // Register
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, UserEntity>> register({
    required String fullName,
    required String username,
    required String password,
    required ProfileType profileType,
    String? email,
    String? phone,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.register(
          fullName: fullName,
          username: username,
          password: password,
          profileType: profileType,
          email: email,
          phone: phone,
        );
        await _persistSession(user);
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
      }
    }
    // Modo offline: crea un usuario local temporal.
    return _registerOffline(
      fullName: fullName,
      username: username,
      email: email,
      phone: phone,
    );
  }

  // ---------------------------------------------------------------------------
  // Get current user (desde cache)
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() => _getLocalUser();

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final accessToken = await tokenStorage.getAccessToken();
          final refreshToken = await tokenStorage.getRefreshToken();
          await remoteDataSource.logout(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
        } on ServerException {
          // Si el servidor falla, igual limpiamos local para no dejar al
          // usuario atrapado.
        }
      }
      await localDataSource.clearCache();
      await tokenStorage.clearTokens();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh session (llamada explícita desde BLoC si se necesita)
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, UserEntity>> refreshSession() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());

    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        return const Left(
          AuthFailure(message: 'No hay token de refresco disponible.'),
        );
      }

      final refreshedUser = await remoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );
      await _persistSession(refreshedUser);
      return Right(refreshedUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  // ---------------------------------------------------------------------------
  // Profile type
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> saveSelectedProfileType(
      ProfileType profileType) async {
    try {
      await localDataSource.cacheSelectedProfileType(profileType.key);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ProfileType?>> getSelectedProfileType() async {
    try {
      final key = await localDataSource.getSelectedProfileType();
      if (key == null) return const Right(null);
      return Right(ProfileType.fromKey(key));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers privados
  // ---------------------------------------------------------------------------

  /// Persiste el usuario autenticado en cache local Y los tokens en TokenStorage.
  Future<void> _persistSession(UserModel user) async {
    await localDataSource.cacheUser(user);
    if (user.accessToken != null && user.refreshToken != null) {
      await tokenStorage.saveTokens(
        accessToken: user.accessToken!,
        refreshToken: user.refreshToken!,
      );
    }
  }

  Future<Either<Failure, UserEntity>> _getLocalUser() async {
    try {
      final cachedUser = await localDataSource.getLastUser();
      // Verify the token is still in TokenStorage — if the interceptor cleared
      // it due to a refresh failure, we treat the session as invalid so the
      // user is sent to login instead of landing on a broken home screen.
      final storedToken = await tokenStorage.getAccessToken();
      if (storedToken == null || storedToken.isEmpty) {
        return const Left(
          CacheFailure(message: 'No hay sesión activa. Vuelve a iniciar sesión.'),
        );
      }
      return Right(cachedUser);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  Future<Either<Failure, UserEntity>> _registerOffline({
    required String fullName,
    required String username,
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
}
