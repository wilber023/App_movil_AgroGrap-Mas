// =============================================================================
// Core -- Logging Interceptor
// =============================================================================
// Solo activo en modo debug (kDebugMode). Imprime método, path, status code
// y body de request/response sin saturar los logs de producción.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP →] ${options.method} ${options.path}');
      if (options.data != null) debugPrint('         body: ${options.data}');
    }
    handler.next(options);
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
