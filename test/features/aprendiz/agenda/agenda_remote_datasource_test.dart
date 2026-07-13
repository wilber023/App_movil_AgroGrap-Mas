import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrograp_movil/core/error/exceptions.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/data/datasources/agenda_remote_datasource.dart';

/// Adapter falso de Dio (mismo patrón que knowledge_remote_datasource_test.dart
/// -- este proyecto no tiene mocktail/mockito como dependencia).
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

// Respuestas reales verificadas con curl contra 52.1.110.21:8000 (rol
// agricultor) -- ver agenda_backend_implementacion.md.
const _overviewJson = {
  'cropContext': {'cropName': 'tomate', 'currentStage': 'floración', 'currentWeek': 1},
  'activities': [
    {
      'id': 'act_1',
      'title': 'Eliminar plantas afectadas',
      'description': 'Eliminar plantas afectadas',
      'checklist': [],
      'scheduledDate': '2026-07-13T01:17:19.000Z',
      'weekNumber': 1,
      'status': 'pending',
      'category': 'tratamiento',
      'isPendingSync': false,
    },
    {
      'id': 'act_2',
      'title': 'Aplicar fungicida cúprico cada 7 días',
      'description': 'Aplicar fungicida cúprico cada 7 días',
      'checklist': [],
      'scheduledDate': '2026-07-20T01:17:19.000Z',
      'weekNumber': 2,
      'status': 'pending',
      'category': 'tratamiento',
      'isPendingSync': false,
    },
  ],
};

const _emptyOverviewJson = {
  'cropContext': {'cropName': '', 'currentStage': '', 'currentWeek': 0},
  'activities': <dynamic>[],
};

void main() {
  group('AgendaRemoteDataSourceImpl.generar', () {
    test('200 con datos reales del README -> parsea el overview generado', () async {
      RequestOptions? captured;
      final dio = _dioWith((options) async {
        captured = options;
        return _jsonResponse(_overviewJson, 200);
      });
      final datasource = AgendaRemoteDataSourceImpl(client: dio);

      final result = await datasource.generar(
        'agricultor',
        const GenerarAgendaParams(
          cultivo: 'tomate',
          enfermedad: 'tizón tardío',
          tratamiento: '- Eliminar plantas afectadas\n- Aplicar fungicida cúprico cada 7 días',
          prevencion: '- Rotación de cultivos',
          currentStage: 'floración',
        ),
      );

      expect(captured!.path, '/api/v1/agricultor/agenda/generar');
      expect(captured!.method, 'POST');
      expect((captured!.data as Map)['cultivo'], 'tomate');
      expect(result.cropContext.cropName, 'tomate');
      expect(result.activities, hasLength(2));
      expect(result.activities.first.id, 'act_1');
    });
  });

  group('AgendaRemoteDataSourceImpl.getAgendaOverview', () {
    test('200 con overview -> parsea actividades reales', () async {
      final dio = _dioWith((_) async => _jsonResponse(_overviewJson, 200));
      final datasource = AgendaRemoteDataSourceImpl(client: dio);

      final result = await datasource.getAgendaOverview('agricultor');

      expect(result.cropContext.cropName, 'tomate');
      expect(result.activities, hasLength(2));
    });

    test('200 vacío (usuario nuevo, sin generar todavía) -> overview sin actividades', () async {
      final dio = _dioWith((_) async => _jsonResponse(_emptyOverviewJson, 200));
      final datasource = AgendaRemoteDataSourceImpl(client: dio);

      final result = await datasource.getAgendaOverview('aprendiz');

      expect(result.cropContext.cropName, '');
      expect(result.activities, isEmpty);
    });

    test('401 -> ServerException con statusCode 401', () async {
      final dio = _dioWith((options) async => throw DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 401, data: {'detail': 'Unauthorized'}),
            type: DioExceptionType.badResponse,
          ));
      final datasource = AgendaRemoteDataSourceImpl(client: dio);

      expect(
        () => datasource.getAgendaOverview('agricultor'),
        throwsA(isA<ServerException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });
  });

  group('AgendaRemoteDataSourceImpl.completeActivity / postponeActivity', () {
    test('complete 200 -> status completed', () async {
      final dio = _dioWith((_) async => _jsonResponse({
            'id': 'act_1',
            'title': 'Eliminar plantas afectadas',
            'description': 'Eliminar plantas afectadas',
            'checklist': [],
            'scheduledDate': '2026-07-13T01:17:19.000Z',
            'weekNumber': 1,
            'status': 'completed',
            'category': 'tratamiento',
            'isPendingSync': false,
          }, 200));
      final datasource = AgendaRemoteDataSourceImpl(client: dio);

      final result = await datasource.completeActivity('agricultor', 'act_1');

      expect(result.id, 'act_1');
      expect(result.status.name, 'completed');
    });

    test('postpone 200 con reason -> status postponed', () async {
      RequestOptions? captured;
      final dio = _dioWith((options) async {
        captured = options;
        return _jsonResponse({
          'id': 'act_2',
          'title': 'Aplicar fungicida cúprico cada 7 días',
          'description': 'Aplicar fungicida cúprico cada 7 días',
          'checklist': [],
          'scheduledDate': '2026-07-20T01:17:19.000Z',
          'weekNumber': 2,
          'status': 'postponed',
          'category': 'tratamiento',
          'isPendingSync': false,
        }, 200);
      });
      final datasource = AgendaRemoteDataSourceImpl(client: dio);

      final result = await datasource.postponeActivity('agricultor', 'act_2', 'lluvia');

      expect((captured!.data as Map)['reason'], 'lluvia');
      expect(result.status.name, 'postponed');
    });

    test('complete sobre actividad inexistente -> ServerException con statusCode 404', () async {
      final dio = _dioWith((options) async => throw DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 404,
              data: {'detail': 'Actividad no encontrada'},
            ),
            type: DioExceptionType.badResponse,
          ));
      final datasource = AgendaRemoteDataSourceImpl(client: dio);

      expect(
        () => datasource.completeActivity('agricultor', 'act_no_existe'),
        throwsA(isA<ServerException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });
}
