// =============================================================================
// Feature: Auth -- Fuente de Datos Remota
// =============================================================================
// Capa: Data / DataSources
// Hace las llamadas HTTP reales al microservicio de usuarios usando Dio.
// Lanza [ServerException] para que [AuthRepositoryImpl] lo convierta en
// [Failure] y lo propague hacia la capa de presentación.
//
// Endpoints (todos bajo baseUrl = http://174.129.218.190/api/v1):
//   POST /auth/login
//   POST /auth/register/agricultor
//   POST /auth/register/aprendiz
//   POST /auth/refresh
//   POST /auth/logout
// =============================================================================

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/profile_type.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserModel> login({
    required String username,
    required String password,
  });

  /// [profileType] determina el endpoint de registro:
  ///   - agricultor      → POST /auth/register/agricultor
  ///   - aprendizAgricola → POST /auth/register/aprendiz
  Future<UserModel> register({
    required String fullName,
    required String username,
    required String password,
    required ProfileType profileType,
    String? email,
    String? phone,
  });

  Future<UserModel> refreshToken({required String refreshToken});

  Future<void> logout({String? accessToken, String? refreshToken});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio client;

  const AuthRemoteDataSourceImpl({required this.client});

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await client.post(
        ApiEndpoints.auth.login,
        data: {
          'username': username,
          'password': password,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Register (enruta por profileType)
  // ---------------------------------------------------------------------------

  @override
  Future<UserModel> register({
    required String fullName,
    required String username,
    required String password,
    required ProfileType profileType,
    String? email,
    String? phone,
  }) async {
    final endpoint = profileType == ProfileType.agricultor
        ? ApiEndpoints.auth.registerAgricultor
        : ApiEndpoints.auth.registerAprendiz;

    final body = <String, dynamic>{
      'fullName': fullName,
      'username': username,
      'password': password,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };

    try {
      final response = await client.post(endpoint, data: body);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh token
  // ---------------------------------------------------------------------------

  @override
  Future<UserModel> refreshToken({required String refreshToken}) async {
    try {
      final response = await client.post(
        ApiEndpoints.auth.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Logout — invalida ambos tokens en el servidor
  // ---------------------------------------------------------------------------

  @override
  Future<void> logout({String? accessToken, String? refreshToken}) async {
    // Enviar ambos tokens para invalidación completa (blacklist + Redis).
    final body = <String, dynamic>{
      if (accessToken != null) 'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
    };

    try {
      await client.post(ApiEndpoints.auth.logout, data: body);
    } on DioException catch (e) {
      // Los errores de logout no deben bloquear el cierre de sesión local.
      // Solo re-lanzamos si es un error de red sin respuesta (sin conectividad).
      if (e.response == null) throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Mapeo de errores Dio → ServerException con mensajes seguros para el usuario
  // ---------------------------------------------------------------------------

  ServerException _mapDioException(DioException e) {
    // Sin respuesta del servidor: error de red/timeout.
    // NUNCA exponer e.message aquí porque contiene detalles técnicos internos
    // (duración del timeout, stack de conexión, etc.).
    if (e.response == null) {
      return ServerException(
        message: _networkErrorMessage(e.type),
        statusCode: null,
      );
    }

    final statusCode = e.response!.statusCode;
    // El ErrorInterceptor ya enriqueció e.message con el campo "detail" del
    // backend. Si está vacío, usamos el mensaje por defecto según el status code.
    final message = (e.message != null && e.message!.isNotEmpty)
        ? e.message!
        : _defaultMessageFor(statusCode);
    return ServerException(message: message, statusCode: statusCode);
  }

  /// Mensajes amigables para errores de red sin respuesta del servidor.
  String _networkErrorMessage(DioExceptionType type) => switch (type) {
        DioExceptionType.connectionTimeout =>
          'Sin conexión. Verifica tu red e intenta de nuevo.',
        DioExceptionType.sendTimeout =>
          'No se pudo enviar la solicitud. Verifica tu conexión.',
        DioExceptionType.receiveTimeout =>
          'El servidor tardó demasiado. Intenta de nuevo más tarde.',
        DioExceptionType.connectionError =>
          'Sin conexión a internet. Activa tu red e intenta de nuevo.',
        DioExceptionType.cancel => 'La solicitud fue cancelada.',
        _ => 'No se pudo conectar al servidor. Intenta más tarde.',
      };

  String _defaultMessageFor(int? code) => switch (code) {
        400 => 'El nombre de usuario o correo ya están en uso.',
        401 => 'Credenciales incorrectas o sesión expirada.',
        403 => 'No tienes permisos para realizar esta acción.',
        404 => 'Recurso no encontrado.',
        422 => 'Datos inválidos. Revisa el formulario.',
        500 => 'Error interno del servidor. Intenta más tarde.',
        _ => 'Ocurrió un error inesperado. Intenta de nuevo.',
      };
}
