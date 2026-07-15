import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/subscribe_result_model.dart';
import '../models/subscription_model.dart';

abstract interface class SubscriptionRemoteDataSource {
  Future<SubscribeResultModel> subscribe({required String plan});
  Future<SubscriptionModel?> getSubscription();
  Future<void> cancel();
}

/// Datasource del microservicio de pagos (ver API.md).
///
/// IMPORTANTE: [client] es el MISMO `Dio` compartido que usan el resto de
/// las features (Auth, Home, Treatment...), registrado una unica vez en
/// `_initCore()` con su `AuthInterceptor`/`ErrorInterceptor`/`LoggingInterceptor`.
/// No se crea una instancia de Dio dedicada para esta feature: hacerlo
/// duplicaba el `AuthInterceptor` (con su propio flag `_isRefreshing`),
/// lo que podia competir en paralelo con el interceptor del Dio principal
/// por renovar el token y terminar invalidando la sesion. Como el
/// microservicio de pagos vive en un host distinto, cada endpoint se pide
/// con una URL absoluta (`_url`), que Dio respeta ignorando el `baseUrl`
/// del cliente compartido, sin perder ninguno de sus interceptores.
///
/// Los mensajes de error mostrados al usuario NUNCA reflejan el detalle
/// crudo del backend/PayPal: se mapean a texto fijo y seguro por codigo
/// HTTP (ver [_defaultMessage]).
class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final Dio client;

  const SubscriptionRemoteDataSourceImpl({required this.client});

  static const String _returnUrl = 'agrograph://payment/success';
  static const String _cancelUrl = 'agrograph://payment/cancel';

  String _url(String path) => '${ApiEndpoints.subscriptionsBaseUrl}$path';

  @override
  Future<SubscribeResultModel> subscribe({required String plan}) async {
    try {
      final response = await client.post(
        _url(ApiEndpoints.subscription.subscribe),
        data: {
          'plan': plan,
          'return_url': _returnUrl,
          'cancel_url': _cancelUrl,
        },
      );
      return SubscribeResultModel.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw const ServerException(
        message: 'No se pudo iniciar la suscripción. Intenta nuevamente más tarde.',
        statusCode: null,
      );
    }
  }

  @override
  Future<SubscriptionModel?> getSubscription() async {
    if (kDebugMode) {
      debugPrint('[SUB-TRACE] 6) SubscriptionRemoteDataSourceImpl.getSubscription -- '
          'GET ${_url(ApiEndpoints.subscription.current)} (justo antes del request HTTP)');
    }
    try {
      final response = await client.get(_url(ApiEndpoints.subscription.current));
      if (kDebugMode) {
        debugPrint('[SUB-TRACE] 9b) Respuesta OK ${response.statusCode} -- '
            'Authorization enviado: ${_maskAuth(response.requestOptions.headers['Authorization'])}');
      }
      return SubscriptionModel.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _mapError(e);
    } catch (_) {
      throw const ServerException(
        message: 'No se pudo consultar tu suscripción. Intenta nuevamente más tarde.',
        statusCode: null,
      );
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await client.post(_url(ApiEndpoints.subscription.cancel), data: const {});
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw const ServerException(
        message: 'No se pudo cancelar tu suscripción. Intenta nuevamente más tarde.',
        statusCode: null,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Mapeo de errores -- nunca expone el `error`/`detail` crudo del backend.
  // ---------------------------------------------------------------------------

  ServerException _mapError(DioException e) {
    if (kDebugMode) _debugLogFailedRequest(e);
    if (e.response == null) {
      return ServerException(message: _networkMessage(e.type), statusCode: null);
    }
    final code = e.response!.statusCode;
    final message = _defaultMessage(code);
    if (kDebugMode) {
      debugPrint('[SUB-TRACE] 9) AuthInterceptor/backend devolvieron el error final -- '
          'statusCode=$code');
      debugPrint('[SUB-TRACE] 9a) Body crudo del backend: ${e.response?.data}');
      debugPrint('[SUB-TRACE] 10) _mapError -- statusCode=$code -> _defaultMessage() '
          'transforma esto en el texto: "$message" (linea _defaultMessage en este archivo)');
    }
    return ServerException(message: message, statusCode: code);
  }

  // ---------------------------------------------------------------------------
  // DEBUG TEMPORAL -- instrumentacion para diagnosticar el 401 de /subscription.
  // Lee `e.requestOptions.headers`, es decir, el header EXACTO que Dio ya
  // adjunto (o no) a esta peticion especifica antes de fallar -- no es una
  // suposicion, es el valor real que salio por la red. Eliminar este metodo,
  // `_maskAuth` y sus llamadas una vez confirmada la causa del 401.
  // ---------------------------------------------------------------------------
  void _debugLogFailedRequest(DioException e) {
    debugPrint('[SUB-TRACE] 8) Respuesta del backend -- '
        '${e.requestOptions.method} ${e.requestOptions.uri}');
    debugPrint('[SUB-TRACE] 8a) Authorization que salio en ESTA peticion (real, no supuesto): '
        '${_maskAuth(e.requestOptions.headers['Authorization'])}');
    debugPrint(
      '[SUB-TRACE] 8b) Status: ${e.response?.statusCode ?? "sin respuesta (${e.type})"}',
    );
  }

  String _maskAuth(Object? authHeader) {
    final value = authHeader?.toString();
    if (value == null) return '(ausente -- no se adjunto ningun Authorization header)';
    return value.length > 22 ? '${value.substring(0, 22)}...' : value;
  }

  String _networkMessage(DioExceptionType type) => switch (type) {
        DioExceptionType.connectionTimeout => 'Sin conexión. Verifica tu red e intenta de nuevo.',
        DioExceptionType.sendTimeout => 'No se pudo enviar la solicitud. Verifica tu conexión.',
        DioExceptionType.receiveTimeout => 'El servidor tardó demasiado. Intenta de nuevo.',
        DioExceptionType.connectionError =>
          'Sin conexión a internet. Activa tu red e intenta de nuevo.',
        _ => 'No se pudo conectar con el servicio de pagos. Intenta más tarde.',
      };

  // 400 == PAYPAL_API_ERROR (unico caso documentado para ese codigo en
  // API.md): restriccion o problema de autorizacion con PayPal.
  //
  // 401: NO se redacta como "tu sesion expiro". Evidencia (ver [SUB-TRACE]
  // 7d/7g en AuthInterceptor): el Access Token del login es valido -- el
  // Paso 1 (POST /auth/refresh) tiene exito y el Paso 2 (reintento con el
  // token ya renovado) sigue recibiendo 401 del microservicio de pagos.
  // Es decir, el 401 no indica una sesion vencida; el propio servicio de
  // pagos esta rechazando un JWT valido (confirmado tambien con curl
  // directo al backend, fuera de la app). Decirle al usuario "tu sesion
  // expiro" lo manda a re-loguearse, algo que no soluciona nada.
  String _defaultMessage(int? code) => switch (code) {
        400 =>
          'PayPal no está disponible en este momento debido a un problema de autorización. '
              'Inténtalo nuevamente más tarde.',
        401 => 'No pudimos confirmar tu cuenta con el servicio de pagos en este momento. '
            'Intenta nuevamente en unos minutos.',
        404 => 'No tienes una suscripción activa.',
        422 => 'No pudimos procesar tu solicitud. Intenta nuevamente más tarde.',
        500 => 'Ocurrió un error en el servidor. Intenta más tarde.',
        _ => 'Ocurrió un error inesperado. Intenta de nuevo.',
      };
}
