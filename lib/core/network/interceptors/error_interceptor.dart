// =============================================================================
// Core -- Error Interceptor
// =============================================================================
// Enriquece los DioException con mensajes legibles extraídos del formato
// estándar de error del backend: { "detail": "Mensaje descriptivo." }
// No cambia el tipo de excepción para no romper los catch blocks de los
// datasources; solo normaliza el mensaje antes de que llegue a ellos.
// =============================================================================

import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final enriched = _enrich(err);
    handler.next(enriched);
  }

  DioException _enrich(DioException err) {
    final response = err.response;
    if (response == null) return err;

    final rawDetail = response.data;
    String detail = err.message ?? 'Error desconocido.';

    if (rawDetail is Map<String, dynamic>) {
      final detailValue = rawDetail['detail'];
      if (detailValue is String && detailValue.isNotEmpty) {
        detail = detailValue;
      } else if (detailValue is List && detailValue.isNotEmpty) {
        // FastAPI 422: detail es una lista de objetos de validación.
        detail = detailValue
            .map((e) => e is Map ? e['msg'] ?? e.toString() : e.toString())
            .join('; ');
      }
    }

    return DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: err.error,
      stackTrace: err.stackTrace,
      message: detail,
    );
  }
}
