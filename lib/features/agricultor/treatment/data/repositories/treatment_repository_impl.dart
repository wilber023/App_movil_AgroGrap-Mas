import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/services/notification_service.dart';
import '../../../../aprendiz/agenda/domain/entities/agenda_activity_entity.dart';
import '../../../../aprendiz/agenda/domain/entities/agenda_overview_entity.dart';
import '../../../../aprendiz/agenda/domain/repositories/agenda_repository.dart';
import '../../domain/entities/treatment_entity.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../datasources/treatment_local_datasource.dart';

/// Agenda real de Agricultor: un solo plan de tratamiento activo por vez
/// (mismo modelo que expone el backend -- `POST generar` reemplaza el
/// anterior), respaldado por `AgendaRepository` (rol 'agricultor', ver
/// injection_container.dart) para el overview real + fallback offline, y
/// por [TreatmentLocalDataSource] para lo que el backend no modela
/// (metadatos del diagnóstico origen, overrides de reprogramación de
/// fecha, marca de hora de completado, flag de recordatorios).
class TreatmentRepositoryImpl implements TreatmentRepository {
  final AgendaRepository agendaRepository;
  final TreatmentLocalDataSource localDataSource;

  const TreatmentRepositoryImpl({
    required this.agendaRepository,
    required this.localDataSource,
  });

  static const _entityId = 'current';

  @override
  Future<Either<Failure, void>> generateFromDiagnosis({
    required String diagnosisId,
    required String diseaseName,
    required String cropName,
    required String llmDiagnostico,
    required String llmTratamiento,
    required String llmPrevencion,
  }) async {
    final result = await agendaRepository.generarAgenda(
      cultivo: cropName,
      enfermedad: diseaseName,
      tratamiento: llmTratamiento,
      prevencion: llmPrevencion.isNotEmpty ? llmPrevencion : null,
    );
    Failure? failure;
    result.fold((f) => failure = f, (_) => null);
    if (failure != null) return Left(failure!);

    await localDataSource.saveState({
      'diagnosisId': diagnosisId,
      'diseaseName': diseaseName,
      'llmDiagnostico': llmDiagnostico,
      'llmTratamiento': llmTratamiento,
      'llmPrevencion': llmPrevencion,
      'createdAt': DateTime.now().toIso8601String(),
      'remindersActive': true,
      'rescheduleOverrides': <String, String>{},
      'completedAtOverrides': <String, String>{},
    });
    return const Right(null);
  }

  /// El único uso de este check es la UI (botón "Agregar a la agenda" del
  /// resultado de diagnóstico): con el modelo de un solo plan activo, un
  /// diagnóstico que se agregó y luego fue reemplazado por otro ya NO debe
  /// mostrarse como "en agenda" -- por eso se compara contra el
  /// `diagnosisId` guardado, no contra un flag por-diagnóstico que nunca se
  /// limpia (ver agenda_backend_implementacion.md, hallazgo del bug).
  @override
  bool isActivePlanFor(String diagnosisId) {
    final state = localDataSource.getState();
    return state != null && state['diagnosisId'] == diagnosisId;
  }

  @override
  Future<Either<Failure, List<TreatmentEntity>>> getAgenda() async {
    final result = await agendaRepository.getAgendaOverview();
    Failure? failure;
    AgendaOverviewEntity? overview;
    result.fold((f) => failure = f, (o) => overview = o);
    if (failure != null) return Left(failure!);
    if (overview == null || overview!.activities.isEmpty) return const Right([]);

    final entity = await _buildEntity(overview!);
    return Right([entity]);
  }

  @override
  Future<Either<Failure, TreatmentEntity>> getById(String id) async {
    final result = await getAgenda();
    return result.fold(
      (f) => Left(f),
      (list) {
        final found = list.where((t) => t.id == id).toList();
        if (found.isEmpty) {
          return const Left(CacheFailure(message: 'Tratamiento no encontrado'));
        }
        return Right(found.first);
      },
    );
  }

  @override
  Future<Either<Failure, void>> markStepComplete({
    required String treatmentId,
    required String stepId,
  }) async {
    final result = await agendaRepository.completeActivity(stepId);
    Failure? failure;
    result.fold((f) => failure = f, (_) => null);
    if (failure != null) return Left(failure!);

    final state = Map<String, dynamic>.from(localDataSource.getState() ?? {});
    final completedAt = Map<String, dynamic>.from(state['completedAtOverrides'] as Map? ?? {});
    completedAt[stepId] = DateTime.now().toIso8601String();
    state['completedAtOverrides'] = completedAt;
    await localDataSource.saveState(state);
    return const Right(null);
  }

  /// El backend no soporta mover una actividad a una fecha arbitraria (solo
  /// `postpone`, que marca "pospuesto" sin fecha propia -- distinto de lo
  /// que este selector de fecha necesita). Se mantiene 100% local, igual
  /// que antes de conectar el backend.
  @override
  Future<Either<Failure, void>> rescheduleStep({
    required String treatmentId,
    required String stepId,
    required DateTime newDate,
  }) async {
    final state = Map<String, dynamic>.from(localDataSource.getState() ?? {});
    final overrides = Map<String, dynamic>.from(state['rescheduleOverrides'] as Map? ?? {});
    overrides[stepId] = newDate.toIso8601String();
    state['rescheduleOverrides'] = overrides;
    await localDataSource.saveState(state);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> setRemindersActive({
    required String treatmentId,
    required bool active,
  }) async {
    final state = Map<String, dynamic>.from(localDataSource.getState() ?? {});
    state['remindersActive'] = active;
    await localDataSource.saveState(state);
    return const Right(null);
  }

  Future<TreatmentEntity> _buildEntity(AgendaOverviewEntity overview) async {
    final state = localDataSource.getState() ?? const {};
    final rescheduleOverrides = Map<String, dynamic>.from(state['rescheduleOverrides'] as Map? ?? {});
    final completedAtOverrides = Map<String, dynamic>.from(state['completedAtOverrides'] as Map? ?? {});
    final remindersActive = state['remindersActive'] as bool? ?? true;

    final steps = _buildSteps(overview.activities, rescheduleOverrides, completedAtOverrides);
    final completedSteps = steps.where((s) => s.isCompleted).length;

    final entity = TreatmentEntity(
      id: _entityId,
      diseaseName: state['diseaseName'] as String? ?? '',
      cropName: overview.cropContext.cropName,
      llmDiagnostico: state['llmDiagnostico'] as String? ?? '',
      llmTratamiento: state['llmTratamiento'] as String? ?? '',
      llmPrevencion: state['llmPrevencion'] as String? ?? '',
      totalSteps: steps.length,
      completedSteps: completedSteps,
      remindersActive: remindersActive,
      steps: steps,
      createdAt: DateTime.tryParse(state['createdAt'] as String? ?? '') ?? DateTime.now(),
    );

    // La lectura de la agenda (esta funcion) nunca debe fallar por un
    // problema del plugin de notificaciones locales (no listo, sin
    // permiso, etc.) -- sincronizar el recordatorio es un efecto
    // secundario best-effort, no parte del resultado que se le debe al
    // usuario.
    try {
      await _syncReminder(entity);
    } catch (_) {}
    return entity;
  }

  /// Primer paso no completado = "programado" (el activo); el resto de los
  /// no completados quedan "pendiente". `postponed` se trata como
  /// "pendiente": Treatment no tiene un cuarto estado visual para eso.
  List<TreatmentStepEntity> _buildSteps(
    List<AgendaActivityEntity> activities,
    Map<String, dynamic> rescheduleOverrides,
    Map<String, dynamic> completedAtOverrides,
  ) {
    final statuses = activities.map((a) {
      return a.status == AgendaActivityStatus.completed ? 'completado' : 'pendiente';
    }).toList();
    for (var i = 0; i < statuses.length; i++) {
      if (statuses[i] != 'completado') {
        statuses[i] = 'programado';
        break;
      }
    }

    return List.generate(activities.length, (i) {
      final a = activities[i];
      final overrideRaw = rescheduleOverrides[a.id] as String?;
      final scheduledDate =
          overrideRaw != null ? (DateTime.tryParse(overrideRaw) ?? a.scheduledDate) : a.scheduledDate;
      final completedAtRaw = completedAtOverrides[a.id] as String?;

      return TreatmentStepEntity(
        id: a.id,
        stepNumber: i + 1,
        title: a.title,
        description: a.description,
        status: statuses[i],
        scheduledDate: scheduledDate,
        completedDate: completedAtRaw != null ? DateTime.tryParse(completedAtRaw) : null,
      );
    });
  }

  /// Mantiene los recordatorios del sistema alineados con el paso activo
  /// actual. Se llama en cada `getAgenda()` para cubrir automáticamente los
  /// cambios hechos por `markStepComplete`/`rescheduleStep`.
  Future<void> _syncReminder(TreatmentEntity treatment) async {
    for (final step in treatment.steps) {
      await NotificationService.instance
          .cancel(NotificationService.stableId(treatment.id, step.id));
    }
    if (!treatment.remindersActive) return;

    final active = treatment.activeStep;
    if (active == null) return;

    final reminderDay = active.scheduledDate.subtract(const Duration(days: 1));
    final reminderTime = DateTime(
      reminderDay.year,
      reminderDay.month,
      reminderDay.day,
      8,
    );

    await NotificationService.instance.scheduleReminder(
      id: NotificationService.stableId(treatment.id, active.id),
      title: '${treatment.diseaseName} en ${treatment.cropName}',
      body: active.title,
      whenLocal: reminderTime,
    );
  }
}
