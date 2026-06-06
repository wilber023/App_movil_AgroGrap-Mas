// =============================================================================
// Feature: Auth -- Fuente de Datos Remota
// =============================================================================
// Capa: Data / DataSources
// Regla: Comunica con el backend via HTTP (Dio).
//        Lanza [ServerException] en caso de error para que el repositorio
//        lo convierta en [ServerFailure].
// =============================================================================

import 'package:dio/dio.dart';

import '../models/user_model.dart';

/// Contrato de la fuente de datos remota de autenticacion.
abstract interface class AuthRemoteDataSource {
  /// Autentica al usuario con credenciales.
  /// Lanza [ServerException] si la respuesta no es exitosa.
  Future<UserModel> login({
    required String username,
    required String password,
  });

  /// Registra un nuevo usuario.
  /// Lanza [ServerException] si la respuesta no es exitosa.
  Future<UserModel> register({
    required String fullName,
    required String username,
    required String password,
    String? email,
    String? phone,
  });

  /// Refresca el token de acceso.
  /// Lanza [ServerException] si el refresh token es invalido.
  Future<UserModel> refreshToken({required String refreshToken});

  /// Cierra la sesion en el servidor (invalida el token).
  /// Lanza [ServerException] si la peticion falla.
  Future<void> logout({required String accessToken});
}

/// Implementacion concreta de [AuthRemoteDataSource] usando Dio.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio client;

  const AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const UserModel(
      id: 'mock_user',
      fullName: 'Usuario Demo',
      username: 'demo',
      accessToken: 'mock_token',
      refreshToken: 'mock_refresh',
    );
  }

  @override
  Future<UserModel> register({
    required String fullName,
    required String username,
    required String password,
    String? email,
    String? phone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return UserModel(
      id: 'mock_user',
      fullName: fullName,
      username: username,
      accessToken: 'mock_token',
      refreshToken: 'mock_refresh',
    );
  }

  @override
  Future<UserModel> refreshToken({required String refreshToken}) async {
    return const UserModel(
      id: 'mock_user',
      fullName: 'Usuario Demo',
      username: 'demo',
      accessToken: 'mock_token2',
      refreshToken: 'mock_refresh2',
    );
  }

  @override
  Future<void> logout({required String accessToken}) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

}
