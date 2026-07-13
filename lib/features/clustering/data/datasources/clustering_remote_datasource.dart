import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/alerta_epidemiologica_model.dart';
import '../models/estado_resumen_model.dart';

abstract interface class ClusteringRemoteDataSource {
  Future<MapaCampaniasModel> getMapaCampanias();

  Future<AlertaEpidemiologicaModel> getAlerta({String? estado});
}

/// Consume el mapa epidemiológico / alertas del microservicio de
/// diagnóstico (`http://52.1.110.21:8000`). Reutiliza el Dio `'llmDio'`
/// (ya trae `AuthInterceptor` con el Bearer) — no crea un cliente nuevo.
class ClusteringRemoteDataSourceImpl implements ClusteringRemoteDataSource {
  final Dio client;

  const ClusteringRemoteDataSourceImpl({required this.client});

  @override
  Future<MapaCampaniasModel> getMapaCampanias() async {
    try {
      final response = await client.get(ApiEndpoints.clustering.mapaCampanias);
      return MapaCampaniasModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw const ServerException(
          message: 'Error al cargar el mapa epidemiológico.', statusCode: null);
    }
  }

  @override
  Future<AlertaEpidemiologicaModel> getAlerta({String? estado}) async {
    try {
      final response = await client.get(
        ApiEndpoints.clustering.alertas,
        queryParameters: (estado != null && estado.trim().isNotEmpty)
            ? {'estado': estado.trim()}
            : null,
      );
      return AlertaEpidemiologicaModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw const ServerException(
          message: 'Error al cargar la alerta epidemiológica.', statusCode: null);
    }
  }

  ServerException _mapError(DioException e) {
    if (e.response == null) {
      return ServerException(message: _networkMessage(e.type), statusCode: null);
    }
    final code = e.response!.statusCode;
    final detail = _extractDetail(e.response!.data);
    return ServerException(message: detail ?? _defaultMessage(code), statusCode: code);
  }

  String? _extractDetail(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['detail'] ?? data['error'] ?? data['message'])?.toString();
    }
    return null;
  }

  String _networkMessage(DioExceptionType type) => switch (type) {
        DioExceptionType.connectionTimeout =>
          'Sin conexión. Verifica tu red e intenta de nuevo.',
        DioExceptionType.sendTimeout =>
          'No se pudo enviar la solicitud. Verifica tu conexión.',
        DioExceptionType.receiveTimeout =>
          'El servidor tardó demasiado. Intenta de nuevo.',
        DioExceptionType.connectionError =>
          'Sin conexión a internet. Activa tu red e intenta de nuevo.',
        _ => 'No se pudo conectar al servicio de clustering. Intenta más tarde.',
      };

  String _defaultMessage(int? code) => switch (code) {
        401 => 'Sesión expirada. Vuelve a iniciar sesión.',
        403 => 'No tienes permisos para ver esta información.',
        422 => 'Parámetros inválidos.',
        500 => 'Error interno del servidor. Intenta más tarde.',
        _ => 'Ocurrió un error inesperado. Intenta de nuevo.',
      };
}
