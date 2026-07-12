// =============================================================================
// AgroGraph-MAS — KnowledgeRemoteDataSource (offline_knowledge)
// GET /api/v1/offline/catalog + GET /api/v1/offline/documents/{doc_id}.
// Contrato real confirmado en README_ofline.md (secciones 7 y 8).
//
// IMPORTANTE: [client] es el MISMO Dio compartido que usan el resto de las
// features (registrado en _initCore() con AuthInterceptor/ErrorInterceptor/
// LoggingInterceptor). No se usa `ApiClient` (core/network/api_client.dart)
// porque esa clase asume siempre el envelope `{success, data, error}`, y
// estos dos endpoints devuelven el JSON pelado (confirmado en el README) --
// usar ApiClient aquí dejaría `response.data` en null siempre. Se arma la
// URL absoluta con `_url()`, el mismo truco que ya usa
// SubscriptionRemoteDataSourceImpl para Payments: Dio la respeta ignorando
// su `baseUrl` configurado, sin perder ningún interceptor (incluida la
// inyección automática del JWT).
// =============================================================================

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/offline_catalog_document.dart';

abstract interface class KnowledgeRemoteDataSource {
  /// Catálogo completo de documentos descargables (todos los cultivos). La
  /// app filtra client-side por el cultivo que le interese.
  Future<List<OfflineCatalogDocument>> getCatalog();

  /// Descarga el contenido + embeddings de un documento puntual.
  ///
  /// Lanza [NetworkException] (`statusCode: 404` si el `docId` no existe,
  /// `statusCode: null` si no hubo respuesta / timeout) o [ServerException]
  /// en errores 5xx.
  Future<Map<String, dynamic>> downloadDocument(String docId);
}

class KnowledgeRemoteDataSourceImpl implements KnowledgeRemoteDataSource {
  final Dio client;

  KnowledgeRemoteDataSourceImpl({required this.client});

  String _url(String path) => '${ApiEndpoints.offlineKnowledgeBaseUrl}$path';

  @override
  Future<List<OfflineCatalogDocument>> getCatalog() async {
    try {
      final response = await client.get(_url(ApiEndpoints.offlineKnowledge.catalog));
      final data = response.data as Map<String, dynamic>;
      final documents = data['documents'] as List? ?? const [];
      return documents
          .map((e) => OfflineCatalogDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> downloadDocument(String docId) async {
    try {
      final response = await client.get(
        _url(ApiEndpoints.offlineKnowledge.documentById(docId)),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    final code = e.response?.statusCode;
    if (code == null) {
      return NetworkException(message: 'Error de conexión: ${e.message}');
    }
    if (code >= 500) {
      return ServerException(message: 'Error en el servidor ($code).');
    }
    if (code == 401 || code == 403) {
      return UnauthorizedException(message: 'Sesión expirada o no autorizada.');
    }
    return NetworkException(message: 'Error de red ($code).', statusCode: code);
  }
}
