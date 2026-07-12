import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/notification_subscription_model.dart';

abstract interface class NotificationRemoteDataSource {
  Future<NotificationSubscriptionModel> subscribe({
    required String fcmToken,
    required String estado,
    List<String>? cultivos,
  });
  Future<NotificationSubscriptionModel?> getMySubscription();
  Future<void> cancelSubscription();
}

/// Datasource del microservicio de notificaciones (ver
/// integrar_notificaciones.md, raiz del proyecto).
///
/// IMPORTANTE: [client] es el MISMO `Dio` compartido que usan Auth/Home/
/// Subscription (registrado una unica vez en `_initCore()` con su
/// `AuthInterceptor`/`ErrorInterceptor`/`LoggingInterceptor`). No se crea un
/// Dio dedicado: el microservicio de notificaciones solo necesita el mismo
/// JWT compartido, sin headers/timeouts especiales, y un segundo
/// `AuthInterceptor` podria competir por renovar el token (mismo
/// razonamiento que `SubscriptionRemoteDataSourceImpl`). Como el
/// microservicio vive en un host distinto, cada endpoint se pide con una
/// URL absoluta (`_url`), que Dio respeta ignorando el `baseUrl` del
/// cliente compartido sin perder ninguno de sus interceptores.
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio client;

  const NotificationRemoteDataSourceImpl({required this.client});

  String _url(String path) => '${ApiEndpoints.notificationsBaseUrl}$path';

  @override
  Future<NotificationSubscriptionModel> subscribe({
    required String fcmToken,
    required String estado,
    List<String>? cultivos,
  }) async {
    try {
      final response = await client.post(
        _url(ApiEndpoints.notifications.subscribe),
        data: {
          'fcm_token': fcmToken,
          'estado': estado,
          if (cultivos != null && cultivos.isNotEmpty) 'cultivos': cultivos,
        },
      );
      return NotificationSubscriptionModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw const ServerException(
        message: 'No se pudo activar las alertas. Intenta nuevamente más tarde.',
        statusCode: null,
      );
    }
  }

  @override
  Future<NotificationSubscriptionModel?> getMySubscription() async {
    try {
      final response = await client.get(_url(ApiEndpoints.notifications.mine));
      return NotificationSubscriptionModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _mapError(e);
    } catch (_) {
      throw const ServerException(
        message: 'No se pudo consultar tus alertas. Intenta nuevamente más tarde.',
        statusCode: null,
      );
    }
  }

  @override
  Future<void> cancelSubscription() async {
    try {
      await client.delete(_url(ApiEndpoints.notifications.mine));
    } on DioException catch (e) {
      // Sin suscripcion previa: cancelar es un no-op exitoso.
      if (e.response?.statusCode == 404) return;
      throw _mapError(e);
    } catch (_) {
      throw const ServerException(
        message: 'No se pudieron desactivar las alertas. Intenta nuevamente más tarde.',
        statusCode: null,
      );
    }
  }

  ServerException _mapError(DioException e) {
    if (kDebugMode) {
      debugPrint('[Notifications] ${e.requestOptions.method} ${e.requestOptions.uri} -> '
          '${e.response?.statusCode ?? "sin respuesta (${e.type})"}');
    }
    if (e.response == null) {
      return ServerException(message: _networkMessage(e.type), statusCode: null);
    }
    final code = e.response!.statusCode;
    return ServerException(message: _defaultMessage(code), statusCode: code);
  }

  String _networkMessage(DioExceptionType type) => switch (type) {
        DioExceptionType.connectionTimeout => 'Sin conexión. Verifica tu red e intenta de nuevo.',
        DioExceptionType.sendTimeout => 'No se pudo enviar la solicitud. Verifica tu conexión.',
        DioExceptionType.receiveTimeout => 'El servidor tardó demasiado. Intenta de nuevo.',
        DioExceptionType.connectionError =>
          'Sin conexión a internet. Activa tu red e intenta de nuevo.',
        _ => 'No se pudo conectar con el servicio de notificaciones. Intenta más tarde.',
      };

  String _defaultMessage(int? code) => switch (code) {
        401 => 'Tu sesión expiró. Vuelve a iniciar sesión.',
        404 => 'No tienes alertas activas.',
        422 => 'No pudimos procesar tu solicitud. Verifica los datos e intenta de nuevo.',
        500 => 'Ocurrió un error en el servidor. Intenta más tarde.',
        _ => 'Ocurrió un error inesperado. Intenta de nuevo.',
      };
}
