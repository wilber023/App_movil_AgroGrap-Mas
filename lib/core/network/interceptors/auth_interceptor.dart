// =============================================================================
// Core -- Auth Interceptor
// =============================================================================
// Responsabilidades:
//   1. Inyectar "Authorization: Bearer <access_token>" en cada request
//      protegido (omite los paths públicos de /auth).
//   2. Interceptar respuestas 401, llamar a /auth/refresh con el
//      refresh_token, persistir los tokens nuevos y reintentar el request
//      original con el nuevo access_token.
//   3. Si el refresh también falla (401), limpiar tokens locales para
//      forzar al usuario a re-autenticarse.
//
// IMPORTANTE: usa un `refreshDio` independiente (sin interceptores) para
// evitar el loop infinito que produciría usar el Dio principal dentro de
// su propio interceptor de errores.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../api_endpoints.dart';
import '../../session/session_manager.dart';
import '../../storage/token_storage.dart';

// DEBUG TEMPORAL (solicitado para trazar el flujo de Subscription end-to-end):
// imprime solo para requests al microservicio de pagos, para no saturar el
// log del resto de la app. Eliminar junto con sus dos llamadas mas abajo.
bool _isSubDebugTarget(String path) => path.contains('/api/payments');

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  // Dio limpio, sin interceptores, usado exclusivamente para renovar tokens.
  final Dio _refreshDio;

  bool _isRefreshing = false;

  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshDio,
  })  : _tokenStorage = tokenStorage,
        _refreshDio = refreshDio;

  // ---------------------------------------------------------------------------
  // Request: inyectar token si el path no es público
  // ---------------------------------------------------------------------------

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublic = ApiEndpoints.auth.publicPaths
        .any((p) => options.path.endsWith(p));
    final debugTarget = kDebugMode && _isSubDebugTarget(options.path);

    if (debugTarget) {
      debugPrint('[SUB-TRACE] 7) AuthInterceptor.onRequest -- '
          '${options.method} ${options.path} (isPublic=$isPublic)');
    }

    if (!isPublic) {
      final token = await _tokenStorage.getAccessToken();
      if (debugTarget) {
        debugPrint('[SUB-TRACE] 7a) AuthInterceptor -- TokenStorage.getAccessToken() '
            'devolvio: ${token == null ? "null" : "presente, largo=${token.length}, "
                "inicio=${token.substring(0, token.length < 15 ? token.length : 15)}..."}');
      }
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (debugTarget) {
      debugPrint('[SUB-TRACE] 7b) AuthInterceptor -- header final antes de handler.next(): '
          '${options.headers['Authorization'] ?? "(sin Authorization)"}');
    }

    handler.next(options);
  }

  // ---------------------------------------------------------------------------
  // Error: manejar 401 → refresh → retry
  // ---------------------------------------------------------------------------

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final debugTarget = kDebugMode && _isSubDebugTarget(err.requestOptions.path);

    if (debugTarget) {
      debugPrint('[SUB-TRACE] 7c) AuthInterceptor.onError -- statusCode=$statusCode '
          'retried=${err.requestOptions.extra['_retried'] == true} '
          'isRefreshing=$_isRefreshing');
    }

    // Solo actuar en 401 y si este request no es ya un reintento.
    if (statusCode != 401 || err.requestOptions.extra['_retried'] == true) {
      handler.next(err);
      return;
    }

    // Si ya hay un refresh en curso, rechazar directamente (sin queue)
    // para evitar condiciones de carrera. El usuario verá un error de auth
    // que el BLoC manejará como sesión expirada.
    if (_isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;

    // Paso 1: renovar el token. Un fallo AQUI es la unica senal confiable
    // de que la sesion realmente vencio (refresh_token invalido/expirado).
    String newAccessToken;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();

      if (refreshToken == null) {
        await _tokenStorage.clearTokens();
        SessionManager.instance.notifySessionInvalidated();
        handler.next(err);
        return;
      }

      // Llamar a /auth/refresh con el refresh_token actual.
      final refreshResponse = await _refreshDio.post(
        ApiEndpoints.auth.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final data = refreshResponse.data as Map<String, dynamic>;
      newAccessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String;

      // Persistir el nuevo par de tokens (rotación).
      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      if (debugTarget) {
        debugPrint('[SUB-TRACE] 7d) AuthInterceptor -- Paso 1 (POST /auth/refresh) EXITOSO, '
            'token renovado y guardado. La sesion NO se invalido.');
      }
    } on DioException catch (refreshError) {
      // El refresh también falló (token expirado/revocado): limpiar sesión.
      if (debugTarget) {
        debugPrint('[SUB-TRACE] 7e) AuthInterceptor -- Paso 1 (POST /auth/refresh) FALLO '
            'statusCode=${refreshError.response?.statusCode} body=${refreshError.response?.data} '
            '-> ESTA es la unica rama que invalida la sesion global (SessionManager).');
      }
      await _tokenStorage.clearTokens();
      SessionManager.instance.notifySessionInvalidated();
      handler.next(err);
      _isRefreshing = false;
      return;
    } catch (_) {
      await _tokenStorage.clearTokens();
      SessionManager.instance.notifySessionInvalidated();
      handler.next(err);
      _isRefreshing = false;
      return;
    }

    // Paso 2: reintentar el request original con el token ya renovado.
    // IMPORTANTE: si este reintento vuelve a fallar (ej. un microservicio
    // distinto al de Usuarios rechaza el token por otra razon: audiencia,
    // permisos, endpoint especifico), el access_token que acabamos de
    // obtener SIGUE SIENDO VALIDO — no es evidencia de que la sesion
    // vencio. Antes este catch estaba unido al del paso 1 y cualquier
    // fallo aqui tambien cerraba la sesion completa del usuario, aunque
    // el token fuera valido y el problema fuera exclusivo de ese endpoint.
    try {
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      err.requestOptions.extra['_retried'] = true;

      if (debugTarget) {
        debugPrint('[SUB-TRACE] 7f) AuthInterceptor -- Paso 2, reintentando '
            '${err.requestOptions.method} ${err.requestOptions.path} con el token renovado.');
      }

      final retryResponse = await _refreshDio.fetch(err.requestOptions);
      if (debugTarget) {
        debugPrint('[SUB-TRACE] 7g) AuthInterceptor -- Paso 2 EXITOSO '
            '(statusCode=${retryResponse.statusCode}).');
      }
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      if (debugTarget) {
        debugPrint('[SUB-TRACE] 7h) AuthInterceptor -- Paso 2 (reintento) VOLVIO A FALLAR '
            'statusCode=${retryError.response?.statusCode} body=${retryError.response?.data} -- '
            'el token SIGUE SIENDO VALIDO, por eso NO se invalida la sesion aqui. '
            'Se propaga el error tal cual al datasource de Subscription.');
      }
      handler.next(retryError);
    } finally {
      _isRefreshing = false;
    }
  }
}
