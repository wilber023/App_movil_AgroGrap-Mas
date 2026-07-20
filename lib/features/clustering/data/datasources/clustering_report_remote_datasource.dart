// =============================================================================
// AgroGraph-MAS — ClusteringReportRemoteDataSource
// POST /api/admin/reportes — alimenta el sistema de Clustering con cada
// diagnóstico exitoso (cultivo/plaga/estado) para mapas de incidencia,
// estadísticas y alertas por región.
//
// IMPORTANTE: [client] es el MISMO Dio compartido que usa el módulo Offline
// Knowledge (registrado en _initCore() con AuthInterceptor/ErrorInterceptor/
// LoggingInterceptor) — no se crea un cliente ni una configuración de
// autenticación nueva. Se arma la URL absoluta con `_url()`, igual que
// KnowledgeRemoteDataSourceImpl, ya que el host (52.1.110.21:8000) difiere
// del `baseUrl` configurado en ese Dio.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_endpoints.dart';

abstract interface class ClusteringReportRemoteDataSource {
  Future<void> enviarReporte({
    required String cultivo,
    required String plaga,
    required String estado,
  });
}

class ClusteringReportRemoteDataSourceImpl implements ClusteringReportRemoteDataSource {
  final Dio client;

  const ClusteringReportRemoteDataSourceImpl({required this.client});

  String _url(String path) => '${ApiEndpoints.offlineKnowledgeBaseUrl}$path';

  @override
  Future<void> enviarReporte({
    required String cultivo,
    required String plaga,
    required String estado,
  }) async {
    final payload = {
      'cultivo': cultivo,
      'plaga': plaga,
      'estado': estado,
    };
    final url = _url(ApiEndpoints.clustering.reportes);

    if (kDebugMode) {
      debugPrint('[ClusteringReporte] POST $url — payload: $payload');
    }

    try {
      final response = await client.post(url, data: payload);
      if (kDebugMode) {
        debugPrint(
          '[ClusteringReporte] respuesta ${response.statusCode} — ${response.data}',
        );
      }
    } on DioException catch (e) {
      // El ErrorInterceptor compartido recorta `detail` a solo `msg` (pierde
      // el nombre del campo en `loc`). Acá se imprime el body crudo del
      // 422/4xx tal cual lo manda el servidor para poder diagnosticar sin
      // adivinar -- el catch de arriba (ClusteringRepositoryImpl) sigue
      // siendo el que descarta el error silenciosamente para el usuario.
      if (kDebugMode) {
        debugPrint(
          '[ClusteringReporte] ${e.response?.statusCode} body crudo del servidor: ${e.response?.data}',
        );
      }
      rethrow;
    }
  }
}
