import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrograp_movil/core/network/api_exceptions.dart';
import 'package:agrograp_movil/features/offline_knowledge/data/datasources/knowledge_remote_datasource.dart';

/// Adapter falso de Dio: permite simular respuestas HTTP (éxito, 404, 500,
/// timeout) sin depender de un mock framework ni de red real -- este
/// proyecto no tiene mocktail/mockito como dependencia.
class _FakeHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) onFetch;
  _FakeHttpClientAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      'content-type': ['application/json'],
    },
  );
}

Dio _dioWith(Future<ResponseBody> Function(RequestOptions) onFetch) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeHttpClientAdapter(onFetch);
  return dio;
}

void main() {
  group('KnowledgeRemoteDataSourceImpl.getCatalog', () {
    test('200 -> parsea la lista de documentos (JSON pelado, sin envelope)', () async {
      final dio = _dioWith(
        (_) async => _jsonResponse({
          'documents': [
            {
              'id': 'doc_a582640ed8c5',
              'crop_name': 'calabaza',
              'disease_name': 'oidio',
              'title': 'Calabaza — oidio',
              'source': 'Guia INIFAP 2020',
              'size_bytes': 2650,
              'version': '1.0',
            },
          ],
        }, 200),
      );
      final datasource = KnowledgeRemoteDataSourceImpl(client: dio);

      final catalog = await datasource.getCatalog();

      expect(catalog, hasLength(1));
      expect(catalog.first.id, 'doc_a582640ed8c5');
      expect(catalog.first.cropName, 'calabaza');
      expect(catalog.first.diseaseName, 'oidio');
    });

    test('500 del servidor -> ServerException', () async {
      final dio = _dioWith((_) async => _jsonResponse({'detail': 'boom'}, 500));
      final datasource = KnowledgeRemoteDataSourceImpl(client: dio);

      expect(
        () => datasource.getCatalog(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('KnowledgeRemoteDataSourceImpl.downloadDocument', () {
    test('200 -> devuelve el Map tal cual (content + embedding + chunks)', () async {
      final documentJson = {
        'id': 'doc_a582640ed8c5',
        'content': 'texto completo del documento...',
        'size_bytes': 2650,
        'embedding': [0.021, -0.053],
        'chunks': [
          {'id': 'doc_a582640ed8c5_c0', 'index': 0, 'text': '...', 'embedding': [0.01]},
        ],
      };
      final dio = _dioWith((_) async => _jsonResponse(documentJson, 200));
      final datasource = KnowledgeRemoteDataSourceImpl(client: dio);

      final result = await datasource.downloadDocument('doc_a582640ed8c5');

      expect(result['id'], 'doc_a582640ed8c5');
      expect(result['content'], 'texto completo del documento...');
      expect((result['chunks'] as List).length, 1);
    });

    test('404 (doc_id no existe) -> NetworkException con statusCode 404', () async {
      final dio = _dioWith(
        (_) async => _jsonResponse({'detail': 'No existe un documento con ese doc_id'}, 404),
      );
      final datasource = KnowledgeRemoteDataSourceImpl(client: dio);

      expect(
        () => datasource.downloadDocument('doc_inexistente'),
        throwsA(
          isA<NetworkException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('503 (almacén no disponible) -> ServerException', () async {
      final dio = _dioWith(
        (_) async => _jsonResponse({'detail': 'El almacen de documentos no esta disponible'}, 503),
      );
      final datasource = KnowledgeRemoteDataSourceImpl(client: dio);

      expect(
        () => datasource.downloadDocument('doc_a582640ed8c5'),
        throwsA(isA<ServerException>()),
      );
    });

    test('timeout / sin conexión -> NetworkException sin statusCode', () async {
      // Dio NO aplica connectTimeout/receiveTimeout a un adapter custom (eso
      // es responsabilidad del adapter real, ver io_adapter.dart) -- para
      // simular timeout/sin-conexión de forma determinista, el adapter debe
      // lanzar el DioException él mismo, tal como lo haría el adapter IO
      // real al no poder conectar.
      final dio = _dioWith(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        ),
      );
      final datasource = KnowledgeRemoteDataSourceImpl(client: dio);

      expect(
        () => datasource.downloadDocument('doc_a582640ed8c5'),
        throwsA(
          isA<NetworkException>().having((e) => e.statusCode, 'statusCode', null),
        ),
      );
    });
  });
}
