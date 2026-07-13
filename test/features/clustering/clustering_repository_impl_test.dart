import 'package:flutter_test/flutter_test.dart';

import 'package:agrograp_movil/core/error/exceptions.dart';
import 'package:agrograp_movil/core/error/failures.dart';
import 'package:agrograp_movil/features/clustering/data/datasources/clustering_remote_datasource.dart';
import 'package:agrograp_movil/features/clustering/data/models/alerta_epidemiologica_model.dart';
import 'package:agrograp_movil/features/clustering/data/models/estado_resumen_model.dart';
import 'package:agrograp_movil/features/clustering/data/repositories/clustering_repository_impl.dart';

/// Fake en memoria de [ClusteringRemoteDataSource] -- simula respuestas
/// exitosas o excepciones del backend, sin red real (mismo patrón que
/// KnowledgeRepositoryImpl test).
class _FakeClusteringRemoteDataSource implements ClusteringRemoteDataSource {
  MapaCampaniasModel? mapaToReturn;
  AlertaEpidemiologicaModel? alertaToReturn;
  Exception? exceptionToThrow;

  /// Último `estado` recibido en `getAlerta`, para verificar el fallback
  /// cuando el usuario no tiene un estado configurado.
  String? lastEstadoRequested;
  bool estadoWasProvided = false;

  @override
  Future<MapaCampaniasModel> getMapaCampanias() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return mapaToReturn!;
  }

  @override
  Future<AlertaEpidemiologicaModel> getAlerta({String? estado}) async {
    lastEstadoRequested = estado;
    estadoWasProvided = estado != null;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return alertaToReturn!;
  }
}

void main() {
  late _FakeClusteringRemoteDataSource remote;
  late ClusteringRepositoryImpl repository;

  setUp(() {
    remote = _FakeClusteringRemoteDataSource();
    repository = ClusteringRepositoryImpl(remoteDataSource: remote);
  });

  group('getMapaCampanias', () {
    test('200 con datos -> Right con los estados ordenados tal cual llegan', () async {
      remote.mapaToReturn = const MapaCampaniasModel(
        totalCampanias: 128,
        estados: [
          EstadoResumenModel(
            estado: 'Chiapas',
            campanias: 14,
            superficieHa: 25230.5,
            productores: 4820,
            campaniaDominante: 'Roya del cafeto',
            cultivoDominante: 'café',
          ),
        ],
      );

      final result = await repository.getMapaCampanias();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('no debería fallar'),
        (mapa) {
          expect(mapa.totalCampanias, 128);
          expect(mapa.estados, hasLength(1));
          expect(mapa.estados.first.estado, 'Chiapas');
        },
      );
    });

    test('401 -> Left(AuthFailure)', () async {
      remote.exceptionToThrow = const ServerException(
        message: 'Sesión expirada. Vuelve a iniciar sesión.',
        statusCode: 401,
      );

      final result = await repository.getMapaCampanias();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.statusCode, 401);
        },
        (_) => fail('debería fallar'),
      );
    });
  });

  group('getAlerta', () {
    test('200 con hay_alerta: true -> Right con la alerta completa', () async {
      remote.alertaToReturn = const AlertaEpidemiologicaModel(
        hayAlerta: true,
        estado: 'Chiapas',
        mensaje: 'Campaña dominante en Chiapas: Roya del cafeto (café).',
        campaniaDominante: 'Roya del cafeto',
        plagaDominante: 'Hemileia vastatrix',
        cultivoDominante: 'café',
        campanias: 14,
        superficieHa: 25230.5,
      );

      final result = await repository.getAlerta(estado: 'Chiapas');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('no debería fallar'),
        (alerta) {
          expect(alerta.hayAlerta, isTrue);
          expect(alerta.estado, 'Chiapas');
          expect(alerta.plagaDominante, 'Hemileia vastatrix');
        },
      );
      expect(remote.lastEstadoRequested, 'Chiapas');
    });

    test('200 con hay_alerta: false -> Right con hayAlerta en false, sin inventar datos', () async {
      remote.alertaToReturn = const AlertaEpidemiologicaModel(
        hayAlerta: false,
        estado: 'Nacional',
        mensaje: 'No hay campañas activas por el momento.',
      );

      final result = await repository.getAlerta();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('no debería fallar'),
        (alerta) {
          expect(alerta.hayAlerta, isFalse);
          expect(alerta.campaniaDominante, isNull);
          expect(alerta.plagaDominante, isNull);
        },
      );
    });

    test('sin estado del usuario disponible -> se consulta la alerta nacional (estado: null)', () async {
      remote.alertaToReturn = const AlertaEpidemiologicaModel(
        hayAlerta: true,
        estado: 'Nacional',
        mensaje: 'Campaña activa a nivel nacional.',
      );

      await repository.getAlerta(estado: null);

      expect(remote.estadoWasProvided, isFalse);
      expect(remote.lastEstadoRequested, isNull);
    });

    test('401 -> Left(AuthFailure)', () async {
      remote.exceptionToThrow = const ServerException(
        message: 'Sesión expirada. Vuelve a iniciar sesión.',
        statusCode: 401,
      );

      final result = await repository.getAlerta(estado: 'Chiapas');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.statusCode, 401);
        },
        (_) => fail('debería fallar'),
      );
    });

    test('422 (parámetros inválidos) -> Left(ServerFailure) con el statusCode preservado', () async {
      remote.exceptionToThrow = const ServerException(
        message: 'Parámetros inválidos.',
        statusCode: 422,
      );

      final result = await repository.getAlerta(estado: '???');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure, isNot(isA<AuthFailure>()));
          expect(failure.statusCode, 422);
        },
        (_) => fail('debería fallar'),
      );
    });
  });
}
