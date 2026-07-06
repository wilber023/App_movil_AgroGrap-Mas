// =============================================================================
// Core -- Logging Interceptor
// =============================================================================
// Solo activo en modo debug (kDebugMode). Imprime método, path, status code
// y body de request/response sin saturar los logs de producción.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  // MASVS-STORAGE (prevención de fuga de datos sensibles): nunca imprimir
  // contraseñas ni tokens en el log, ni siquiera en modo debug.
  static const _sensitiveKeys = {
    'password',
    'confirmPassword',
    'access_token',
    'refresh_token',
    'refreshToken',
    'token',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP →] ${options.method} ${options.path}');
      if (options.data != null) debugPrint('         body: ${_redact(options.data)}');
    }
    handler.next(options);
  }

  Object? _redact(Object? data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(
            key,
            _sensitiveKeys.contains(key) ? '***REDACTED***' : value,
          ));
    }
    return data;
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP ←] ${response.statusCode} ${response.requestOptions.path}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP ✗] ${err.response?.statusCode ?? "NO_RESP"} '
        '${err.requestOptions.path} — ${err.message}',
      );
    }
    handler.next(err);
  }
}
