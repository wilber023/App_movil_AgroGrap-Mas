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

import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.tokenStorage,
  });

  // Refresh "en vuelo" compartido entre llamadores concurrentes (ver
  // refreshSession() mas abajo).
  Future<Either<Failure, UserEntity>>? _pendingRefresh;

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
  Future<Either<Failure, UserEntity>> refreshSession() {
    // Varias partes de la app pueden detectar un token vencido casi al
    // mismo tiempo al abrir la app (el Splash y el chequeo de sesion del
    // AuthBloc raiz, por ejemplo). Sin esto, cada una dispara su propio
    // POST /auth/refresh con el MISMO refresh token; el backend rota el
    // token en cada uso, asi que la segunda llamada llega con un token ya
    // invalidado por la primera y falla — aunque la sesion sea valida,
    // eso hacia que el usuario terminara viendo el Login. Con este guard,
    // todas las llamadas concurrentes esperan el mismo refresh en curso y
    // reciben el mismo resultado, en vez de competir por el mismo token.
    return _pendingRefresh ??= _doRefreshSession().whenComplete(() {
      _pendingRefresh = null;
    });
  }

  Future<Either<Failure, UserEntity>> _doRefreshSession() async {
    debugPrint('[AUTH] refreshSession: iniciando');
    if (!await networkInfo.isConnected) {
      debugPrint('[AUTH] refreshSession: sin red, aborta');
      return const Left(NetworkFailure());
    }

    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      debugPrint(
        '[AUTH] refreshSession: refreshToken presente=${refreshToken != null} '
        'len=${refreshToken?.length}',
      );
      if (refreshToken == null) {
        return const Left(
          AuthFailure(message: 'No hay token de refresco disponible.'),
        );
      }

      final refreshedUser = await remoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );
      debugPrint(
        '[AUTH] refreshSession: exito, nuevo accessToken='
        '${refreshedUser.accessToken != null}, '
        'nuevo refreshToken=${refreshedUser.refreshToken != null}',
      );
      await _persistSession(refreshedUser);
      return Right(refreshedUser);
    } on ServerException catch (e) {
      debugPrint(
        '[AUTH] refreshSession: ServerException status=${e.statusCode} '
        'msg=${e.message}',
      );
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      debugPrint('[AUTH] refreshSession: CacheException msg=${e.message}');
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      debugPrint('[AUTH] refreshSession: excepcion no prevista: $e');
      return Left(CacheFailure(message: e.toString()));
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
    debugPrint(
      '[AUTH] _persistSession: user=${user.id} '
      'accessToken=${user.accessToken != null} '
      'refreshToken=${user.refreshToken != null}',
    );
    if (user.accessToken != null && user.refreshToken != null) {
      await tokenStorage.saveTokens(
        accessToken: user.accessToken!,
        refreshToken: user.refreshToken!,
      );
      debugPrint('[AUTH] _persistSession: tokens guardados en TokenStorage');
    } else {
      debugPrint(
        '[AUTH] _persistSession: ADVERTENCIA — el backend no devolvio '
        'accessToken/refreshToken, NO se guarda nada en TokenStorage',
      );
    }
  }

  Future<Either<Failure, UserEntity>> _getLocalUser() async {
    try {
      final cachedUser = await localDataSource.getLastUser();
      debugPrint('[AUTH] _getLocalUser: usuario cacheado=${cachedUser.id}');
      // Verify the token is still in TokenStorage — if the interceptor cleared
      // it due to a refresh failure, we treat the session as invalid so the
      // user is sent to login instead of landing on a broken home screen.
      final storedToken = await tokenStorage.getAccessToken();
      debugPrint(
        '[AUTH] _getLocalUser: accessToken presente='
        '${storedToken != null && storedToken.isNotEmpty} '
        'len=${storedToken?.length}',
      );
      if (storedToken == null || storedToken.isEmpty) {
        debugPrint('[AUTH] _getLocalUser: sin accessToken -> Left (a Login)');
        return const Left(
          CacheFailure(message: 'No hay sesión activa. Vuelve a iniciar sesión.'),
        );
      }
      // El access token existe pero puede haber expirado sin que nadie lo
      // haya usado todavía (ej. la app estuvo cerrada más tiempo del que
      // dura el access token — algo normal, para eso existe el refresh
      // token). Antes de invalidar la sesión, se intenta renovarlo: así una
      // sesión larga sigue "logueada" sin pedir credenciales de nuevo.
      final expired = _isTokenExpired(storedToken);
      debugPrint('[AUTH] _getLocalUser: tokenExpirado=$expired');
      if (expired) {
        final connected = await networkInfo.isConnected;
        debugPrint('[AUTH] _getLocalUser: conectado=$connected');
        if (!connected) {
          // Sin red no se puede confirmar ni renovar: se respeta la sesión
          // cacheada, mismo criterio offline-first que ya usa login().
          return Right(cachedUser);
        }
        final refreshResult = await refreshSession();
        return refreshResult.fold(
          (failure) {
            debugPrint(
              '[AUTH] _getLocalUser: refresh fallo tipo=${failure.runtimeType} '
              'msg=${failure.message}',
            );
            if (failure is NetworkFailure) return Right(cachedUser);
            // El refresh token también es inválido/expiró: ahí sí termina
            // la sesión.
            return const Left(
              CacheFailure(message: 'Tu sesión expiró. Vuelve a iniciar sesión.'),
            );
          },
          (refreshedUser) {
            debugPrint('[AUTH] _getLocalUser: refresh exitoso');
            return Right(refreshedUser);
          },
        );
      }
      return Right(cachedUser);
    } on CacheException catch (e) {
      debugPrint('[AUTH] _getLocalUser: CacheException msg=${e.message}');
      return Left(CacheFailure(message: e.message));
    } catch (e, st) {
      // Antes solo se atrapaba CacheException — cualquier otra excepcion
      // (ej. una falla nativa al leer flutter_secure_storage) se propagaba
      // sin control. Se atrapa aqui tambien para no dejar a checkSession()
      // colgado y para poder ver la causa real en el log.
      debugPrint('[AUTH] _getLocalUser: excepcion no prevista: $e\n$st');
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// Decodifica el payload de un JWT (sin verificar firma — eso ya lo hizo
  /// el backend al emitirlo) para leer el claim estándar `exp` (RFC 7519).
  ///
  /// Diseño deliberadamente conservador: si el token no tiene el formato
  /// esperado o no trae `exp`, NO se asume vencido — se conserva el
  /// comportamiento actual (solo exigir que el token exista). Esto evita
  /// que un formato de token inesperado (uno sin `exp`, por ejemplo) deje
  /// a todos los usuarios sin poder entrar. Solo se rechaza la sesión
  /// cuando se puede confirmar POSITIVAMENTE que el token ya venció.
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint(
          '[AUTH] _isTokenExpired: el token no tiene 3 partes '
          '(partes=${parts.length}) -> se asume NO vencido',
        );
        return false;
      }

      var payload = parts[1];
      payload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Url.decode(payload));
      final claims = json.decode(decoded) as Map<String, dynamic>;

      final exp = claims['exp'];
      if (exp is! int) {
        debugPrint(
          '[AUTH] _isTokenExpired: claim "exp" ausente o no es int '
          '(valor=$exp, claves=${claims.keys.toList()}) -> se asume NO vencido',
        );
        return false;
      }

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final result = now.isAfter(expiry);
      debugPrint(
        '[AUTH] _isTokenExpired: exp=$expiry ahora=$now -> vencido=$result',
      );
      return result;
    } catch (e) {
      debugPrint('[AUTH] _isTokenExpired: no se pudo decodificar ($e) -> se asume NO vencido');
      return false;
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
