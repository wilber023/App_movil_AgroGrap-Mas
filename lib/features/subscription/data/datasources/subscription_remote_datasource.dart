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
    try {
      final response = await client.get(_url(ApiEndpoints.subscription.current));
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
    return ServerException(message: _defaultMessage(code), statusCode: code);
  }

  // ---------------------------------------------------------------------------
  // DEBUG TEMPORAL -- instrumentacion para diagnosticar el 401 de /subscription.
  // Lee `e.requestOptions.headers`, es decir, el header EXACTO que Dio ya
  // adjunto (o no) a esta peticion especifica antes de fallar -- no es una
  // suposicion, es el valor real que salio por la red. Eliminar este metodo
  // y su unica llamada (arriba) una vez confirmada la causa del 401.
  // ---------------------------------------------------------------------------
  void _debugLogFailedRequest(DioException e) {
    final authHeader = e.requestOptions.headers['Authorization']?.toString();
    final masked = (authHeader != null && authHeader.length > 22)
        ? '${authHeader.substring(0, 22)}...'
        : (authHeader ?? '(ausente -- no se adjunto ningun Authorization header)');
    debugPrint('[Subscription DEBUG] ${e.requestOptions.method} ${e.requestOptions.uri}');
    debugPrint('[Subscription DEBUG] Authorization: $masked');
    debugPrint(
      '[Subscription DEBUG] Status: ${e.response?.statusCode ?? "sin respuesta (${e.type})"}',
    );
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
  String _defaultMessage(int? code) => switch (code) {
        400 =>
          'PayPal no está disponible en este momento debido a un problema de autorización. '
              'Inténtalo nuevamente más tarde.',
        401 => 'Tu sesión expiró. Vuelve a iniciar sesión.',
        404 => 'No tienes una suscripción activa.',
        422 => 'No pudimos procesar tu solicitud. Intenta nuevamente más tarde.',
        500 => 'Ocurrió un error en el servidor. Intenta más tarde.',
        _ => 'Ocurrió un error inesperado. Intenta de nuevo.',
      };
}
