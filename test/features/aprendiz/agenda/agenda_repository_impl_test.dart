import 'package:flutter_test/flutter_test.dart';

import 'package:agrograp_movil/core/error/failures.dart';
import 'package:agrograp_movil/core/network/network_info.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/data/datasources/agenda_local_datasource.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/data/datasources/agenda_remote_datasource.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/data/models/agenda_activity_model.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/data/models/agenda_overview_model.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/data/repositories/agenda_repository_impl.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/domain/entities/agenda_activity_entity.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/domain/entities/agenda_crop_context_entity.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Red controlable a voluntad, sin depender de connectivity_plus real.
class _FakeNetworkInfo implements NetworkInfo {
  bool connected;
  _FakeNetworkInfo({required this.connected});

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => const Stream.empty();
}

/// Caché en memoria (reemplaza Hive en el test, mismo contrato).
class _FakeLocalDataSource implements AgendaLocalDataSource {
  AgendaOverviewModel? cached;

  @override
  Future<void> cacheOverview(AgendaOverviewModel overview) async => cached = overview;

  @override
  Future<AgendaOverviewModel> getCachedOverview() async =>
      cached ??
      const AgendaOverviewModel(
        cropContext: AgendaCropContextEntity(cropName: '', currentStage: '', currentWeek: 0),
        activities: [],
      );

  @override
  Future<AgendaActivityModel> applyActivityUpdate(AgendaActivityModel activity) async {
    final overview = await getCachedOverview();
    final updated = overview.activities
        .map((a) => a.id == activity.id ? activity : AgendaActivityModel.fromEntity(a))
        .toList();
    cached = AgendaOverviewModel(cropContext: overview.cropContext, activities: updated);
    return activity;
  }
}

class _FakeRemoteDataSource implements AgendaRemoteDataSource {
  bool shouldThrow = false;
  AgendaOverviewModel overviewToReturn = AgendaOverviewModel(
    cropContext: const AgendaCropContextEntity(cropName: 'tomate', currentStage: 'floración', currentWeek: 1),
    activities: [
      AgendaActivityModel(
        id: 'act_1',
        title: 'Eliminar plantas afectadas',
        description: 'Eliminar plantas afectadas',
        scheduledDate: DateTime(2026, 7, 13),
        weekNumber: 1,
        status: AgendaActivityStatus.pending,
      ),
    ],
  );

  @override
  Future<AgendaOverviewModel> generar(String rol, GenerarAgendaParams params) async {
    if (shouldThrow) throw Exception('remote down');
    return overviewToReturn;
  }

  @override
  Future<AgendaOverviewModel> getAgendaOverview(String rol) async {
    if (shouldThrow) throw Exception('remote down');
    return overviewToReturn;
  }

  @override
  Future<AgendaActivityModel> completeActivity(String rol, String activityId) async {
    if (shouldThrow) throw Exception('remote down');
    return AgendaActivityModel(
      id: activityId,
      title: 'x',
      description: 'x',
      scheduledDate: DateTime(2026, 7, 13),
      weekNumber: 1,
      status: AgendaActivityStatus.completed,
    );
  }

  @override
  Future<AgendaActivityModel> postponeActivity(String rol, String activityId, String reason) async {
    if (shouldThrow) throw Exception('remote down');
    return AgendaActivityModel(
      id: activityId,
      title: 'x',
      description: 'x',
      scheduledDate: DateTime(2026, 7, 13),
      weekNumber: 1,
      status: AgendaActivityStatus.postponed,
    );
  }
}

void main() {
  late _FakeRemoteDataSource remote;
  late _FakeLocalDataSource local;
  late _FakeNetworkInfo network;
  late AgendaRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemoteDataSource();
    local = _FakeLocalDataSource();
    network = _FakeNetworkInfo(connected: true);
    repository = AgendaRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      networkInfo: network,
      rol: 'agricultor',
    );
  });

  test(
    'sin conexión y sin caché previa -> getAgendaOverview no revienta, '
    'devuelve el overview vacío local en vez de fallar',
    () async {
      network.connected = false;

      final result = await repository.getAgendaOverview();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('no debería fallar'),
        (overview) => expect(overview.activities, isEmpty),
      );
    },
  );

  test(
    'sin conexión pero con una agenda ya cacheada -> sigue mostrando esa '
    'caché de Hive sin romperse ni perder los datos',
    () async {
      final cachedOverview = AgendaOverviewModel(
        cropContext: AgendaCropContextEntity(cropName: 'maíz', currentStage: 'crecimiento', currentWeek: 2),
        activities: [
          AgendaActivityModel(
            id: 'act_9',
            title: 'Actividad cacheada',
            description: 'Actividad cacheada',
            scheduledDate: DateTime(2026, 7, 13),
            weekNumber: 2,
            status: AgendaActivityStatus.pending,
          ),
        ],
      );
      await local.cacheOverview(cachedOverview);
      network.connected = false;

      final result = await repository.getAgendaOverview();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('no debería fallar'),
        (overview) {
          expect(overview.cropContext.cropName, 'maíz');
          expect(overview.activities, hasLength(1));
        },
      );
    },
  );

  test(
    'sin conexión al completar una actividad -> se guarda local con '
    'isPendingSync: true, sin llamar al remoto ni fallar',
    () async {
      final cachedOverview = AgendaOverviewModel(
        cropContext: AgendaCropContextEntity(cropName: 'tomate', currentStage: 'floración', currentWeek: 1),
        activities: [
          AgendaActivityModel(
            id: 'act_1',
            title: 'Eliminar plantas afectadas',
            description: 'Eliminar plantas afectadas',
            scheduledDate: DateTime(2026, 7, 13),
            weekNumber: 1,
            status: AgendaActivityStatus.pending,
          ),
        ],
      );
      await local.cacheOverview(cachedOverview);
      network.connected = false;

      final result = await repository.completeActivity('act_1');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('no debería fallar'),
        (activity) {
          expect(activity.status, AgendaActivityStatus.completed);
          expect(activity.isPendingSync, isTrue);
        },
      );
    },
  );

  test('generarAgenda sin conexión -> Left(NetworkFailure), no inventa un plan', () async {
    network.connected = false;

    final result = await repository.generarAgenda(
      cultivo: 'tomate',
      tratamiento: '- Paso 1',
    );

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('debería fallar'),
    );
  });
}
