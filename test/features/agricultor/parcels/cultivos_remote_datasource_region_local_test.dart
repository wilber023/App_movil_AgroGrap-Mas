import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:agrograp_movil/core/storage/token_storage.dart';
import 'package:agrograp_movil/features/agricultor/parcels/data/datasources/cultivos_remote_datasource.dart';

/// Adapter falso de Dio (mismo patrón que knowledge_remote_datasource_test.dart
/// -- este proyecto no tiene mocktail/mockito): permite simular la respuesta
/// de `GET /selecciones/mis-selecciones` sin red real.
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

Dio _dioReturningList(List<Map<String, dynamic>> items) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeHttpClientAdapter((_) async {
    return ResponseBody.fromString(
      json.encode(items),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  });
  return dio;
}

/// Fake sin red: solo entrega un access token con un JWT válido (header y
/// firma dummy, payload real) para que `_getUserId()` pueda decodificar el
/// `sub` sin llamar a ningún servidor.
class _FakeTokenStorage implements TokenStorage {
  final String? userId;
  const _FakeTokenStorage(this.userId);

  @override
  Future<String?> getAccessToken() async {
    if (userId == null) return null;
    final payload = base64Url.encode(utf8.encode(json.encode({'sub': userId}))).replaceAll('=', '');
    return 'header.$payload.signature';
  }

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {}

  @override
  Future<void> clearTokens() async {}
}

/// Verifica que `getRegionLocal` lee la caché local (`seleccionesBox`) sin
/// ninguna llamada de red -- es la fuente del campo `estado` en el reporte
/// de diagnóstico a Clustering, y esa integración exige explícitamente que
/// no se consulte el microservicio de Cultivos al momento del diagnóstico.
void main() {
  late Directory tempDir;
  late Box<String> seleccionesBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('selecciones_region_local_test');
    Hive.init(tempDir.path);
    seleccionesBox = await Hive.openBox<String>('selecciones_box');
  });

  tearDown(() async {
    await seleccionesBox.close();
    await tempDir.delete(recursive: true);
  });

  CultivosRemoteDataSourceImpl buildDataSource({String? userId}) {
    return CultivosRemoteDataSourceImpl(
      client: Dio(), // no se usa: getRegionLocal nunca hace una petición HTTP.
      tokenStorage: _FakeTokenStorage(userId),
      seleccionesBox: seleccionesBox,
    );
  }

  test('parcela cacheada con region -> devuelve exactamente ese valor', () async {
    await seleccionesBox.put(
      'sel_user123_parcel1',
      json.encode({
        'id': 'parcel1',
        'seleccion_id': 'parcel1',
        'cultivo_id': 'c1',
        'cultivo_nombre': 'Maíz',
        'nombre_parcela': 'Lote 1',
        'area_ha': 2.0,
        'region': 'Suchiapa, Chiapas',
      }),
    );

    final datasource = buildDataSource(userId: 'user123');

    final region = await datasource.getRegionLocal('parcel1');

    expect(region, 'Suchiapa, Chiapas');
  });

  test('seleccionId no cacheado -> null (no inventa ni consulta red)', () async {
    final datasource = buildDataSource(userId: 'user123');

    final region = await datasource.getRegionLocal('no-existe');

    expect(region, isNull);
  });

  test('sin token/usuario -> null en vez de lanzar', () async {
    final datasource = buildDataSource(userId: null);

    final region = await datasource.getRegionLocal('parcel1');

    expect(region, isNull);
  });

  test('cache de otro usuario -> null (no filtra datos entre cuentas)', () async {
    await seleccionesBox.put(
      'sel_otroUsuario_parcel1',
      json.encode({
        'id': 'parcel1',
        'seleccion_id': 'parcel1',
        'cultivo_id': 'c1',
        'cultivo_nombre': 'Maíz',
        'nombre_parcela': 'Lote 1',
        'area_ha': 2.0,
        'region': 'Suchiapa, Chiapas',
      }),
    );

    final datasource = buildDataSource(userId: 'user123');

    final region = await datasource.getRegionLocal('parcel1');

    expect(region, isNull);
  });

  group('getMisSelecciones -- preservación de region ante un listado que no la trae', () {
    test(
      'ya había una region buena en caché (de crearSeleccion) y el listado la manda vacía '
      '-> NO se pisa con vacío, se conserva la buena',
      () async {
        await seleccionesBox.put(
          'sel_user123_parcel1',
          json.encode({
            'id': 'parcel1',
            'cultivo_id': 'c1',
            'cultivo_nombre': 'Maíz',
            'nombre_parcela': 'pap',
            'area_ha': 1.0,
            'region': 'Suchiapa, Chiapas',
          }),
        );

        final dio = _dioReturningList([
          {
            'id': 'parcel1',
            'cultivo_id': 'c1',
            'cultivo_nombre': 'Maíz',
            'nombre_parcela': 'pap',
            'area_ha': 1.0,
            // El listado no manda `region` esta vez (o la manda vacía) --
            // esto es exactamente lo que se observó en producción.
          },
        ]);

        final datasource = CultivosRemoteDataSourceImpl(
          client: dio,
          tokenStorage: _FakeTokenStorage('user123'),
          seleccionesBox: seleccionesBox,
        );

        final result = await datasource.getMisSelecciones();

        expect(result, hasLength(1));
        expect(result.first.region, 'Suchiapa, Chiapas');

        // Y la caché queda con el valor bueno, no con el vacío del listado.
        final cachedRegion = await datasource.getRegionLocal('parcel1');
        expect(cachedRegion, 'Suchiapa, Chiapas');
      },
    );

    test('el listado sí trae region -> se usa la del listado (no hace falta lo cacheado)', () async {
      await seleccionesBox.put(
        'sel_user123_parcel1',
        json.encode({
          'id': 'parcel1',
          'cultivo_id': 'c1',
          'cultivo_nombre': 'Maíz',
          'nombre_parcela': 'pap',
          'area_ha': 1.0,
          'region': 'Región vieja',
        }),
      );

      final dio = _dioReturningList([
        {
          'id': 'parcel1',
          'cultivo_id': 'c1',
          'cultivo_nombre': 'Maíz',
          'nombre_parcela': 'pap',
          'area_ha': 1.0,
          'region': 'Suchiapa, Chiapas',
        },
      ]);

      final datasource = CultivosRemoteDataSourceImpl(
        client: dio,
        tokenStorage: _FakeTokenStorage('user123'),
        seleccionesBox: seleccionesBox,
      );

      final result = await datasource.getMisSelecciones();

      expect(result.first.region, 'Suchiapa, Chiapas');
    });

    test('sin nada cacheado antes y el listado sin region -> queda vacía (nada que preservar)', () async {
      final dio = _dioReturningList([
        {
          'id': 'parcel1',
          'cultivo_id': 'c1',
          'cultivo_nombre': 'Maíz',
          'nombre_parcela': 'pap',
          'area_ha': 1.0,
        },
      ]);

      final datasource = CultivosRemoteDataSourceImpl(
        client: dio,
        tokenStorage: _FakeTokenStorage('user123'),
        seleccionesBox: seleccionesBox,
      );

      final result = await datasource.getMisSelecciones();

      expect(result.first.region, '');
    });
  });
}
