import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:agrograp_movil/core/error/exceptions.dart';
import 'package:agrograp_movil/core/network/network_info.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/data/datasources/agenda_local_datasource.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/data/datasources/agenda_remote_datasource.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/data/models/agenda_activity_model.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/data/models/agenda_overview_model.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/data/repositories/agenda_repository_impl.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/domain/entities/agenda_activity_entity.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/domain/entities/agenda_crop_context_entity.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Mismo escenario que treatment_repository_impl_test.dart pero para
/// Aprendiz -- "Agregar a mi agenda" -> generar -> marcar completado ->
/// cerrar/reabrir la app (nueva instancia de AgendaLocalDataSource sobre la
/// MISMA caja Hive persistida en disco) -> el cambio sigue ahí.
class _FakeRemote implements AgendaRemoteDataSource {
  @override
  Future<AgendaOverviewModel> generar(String rol, GenerarAgendaParams params) async {
    return AgendaOverviewModel(
      cropContext: AgendaCropContextEntity(cropName: params.cultivo, currentStage: params.currentStage ?? '', currentWeek: 1),
      activities: [
        AgendaActivityModel(
          id: 'act_1',
          title: 'Paso 1',
          description: params.tratamiento,
          scheduledDate: DateTime(2026, 7, 13),
          weekNumber: 1,
          status: AgendaActivityStatus.pending,
        ),
      ],
    );
  }

  @override
  Future<AgendaOverviewModel> getAgendaOverview(String rol) async {
    throw const ServerException(message: 'no debería llamarse en este test', statusCode: null);
  }

  @override
  Future<AgendaActivityModel> completeActivity(String rol, String activityId) async {
    return AgendaActivityModel(
      id: activityId,
      title: 'Paso 1',
      description: 'x',
      scheduledDate: DateTime(2026, 7, 13),
      weekNumber: 1,
      status: AgendaActivityStatus.completed,
    );
  }

  @override
  Future<AgendaActivityModel> postponeActivity(String rol, String activityId, String reason) async {
    throw UnimplementedError();
  }
}

class _AlwaysConnected implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => const Stream.empty();
}

void main() {
  late Directory tempDir;
  late Box<String> box;
  late _FakeRemote remote;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('aprendiz_agenda_persist_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>('aprendiz_agenda_box');
    remote = _FakeRemote();
  });

  tearDown(() async {
    await box.close();
    await tempDir.delete(recursive: true);
  });

  AgendaRepositoryImpl repo() => AgendaRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: AgendaLocalDataSourceImpl(box: box),
        networkInfo: _AlwaysConnected(),
        rol: 'aprendiz',
      );

  test(
    '4) Aprendiz: generar + completar actividad -> persiste tras '
    'cerrar/reabrir la app (misma caja Hive, nueva instancia)',
    () async {
      final generated = await repo().generarAgenda(cultivo: 'maíz', tratamiento: 'aplicar fungicida');
      expect(generated.isRight(), isTrue);

      final completed = await repo().completeActivity('act_1');
      expect(completed.isRight(), isTrue);

      // "Reabrir la app": instancia nueva sobre la misma caja ya persistida.
      final afterRestart = await repo().getAgendaOverview();
      afterRestart.fold(
        (_) => fail('no debería fallar'),
        (overview) {
          expect(overview.activities, hasLength(1));
          expect(overview.activities.first.status, AgendaActivityStatus.completed);
        },
      );
    },
  );
}
