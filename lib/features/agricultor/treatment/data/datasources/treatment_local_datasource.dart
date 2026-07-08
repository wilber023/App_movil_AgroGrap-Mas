import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../../core/services/notification_service.dart';
import '../../../diagnosis/domain/entities/llm_response_entity.dart';
import '../models/treatment_model.dart';

abstract interface class TreatmentLocalDataSource {
  Future<List<TreatmentModel>> getAgenda();
  Future<void> markStepComplete({
    required String treatmentId,
    required String stepId,
  });
  Future<void> rescheduleStep({
    required String treatmentId,
    required String stepId,
    required DateTime newDate,
  });
  Future<void> setRemindersActive({
    required String treatmentId,
    required bool active,
  });
}

class TreatmentLocalDataSourceImpl implements TreatmentLocalDataSource {
  final Box<String> diagnosisBox;
  final Box<String> agendaBox;

  const TreatmentLocalDataSourceImpl({
    required this.diagnosisBox,
    required this.agendaBox,
  });

  @override
  Future<List<TreatmentModel>> getAgenda() async {
    final treatments = <TreatmentModel>[];

    for (final raw in diagnosisBox.values) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;

        final statusLabel = m['statusLabel'] as String? ?? 'Seguimiento';
        if (statusLabel == 'Saludable') continue;

        final llmJson = m['llmResponse'] as Map<String, dynamic>?;
        if (llmJson == null) continue;

        final diagnosisId = m['id'] as String? ?? '';

        // Solo incluir si el usuario lo agregó explícitamente a la agenda
        if (agendaBox.get('agenda_added_$diagnosisId') == null) continue;

        final llm = LlmResponseEntity.fromJson(llmJson);
        final diagnosedAt =
            DateTime.tryParse(m['diagnosedAt'] as String? ?? '') ??
                DateTime.now();

        final storedRaw = agendaBox.get('treatment_$diagnosisId');
        Map<String, dynamic> completions = {};
        if (storedRaw != null) {
          try {
            completions = jsonDecode(storedRaw) as Map<String, dynamic>;
          } catch (_) {}
        }

        final steps = _buildSteps(diagnosisId, diagnosedAt, llm, completions);
        final completedCount = steps.where((s) => s.isCompleted).length;

        // Ausencia de la clave = comportamiento previo (recordatorios
        // activos por defecto), compatible con tratamientos ya existentes.
        final remindersActive =
            agendaBox.get('reminders_$diagnosisId') != 'false';
        final diseaseName = m['diseaseName'] as String? ?? '';
        final cropName = m['cropName'] as String? ?? '';

        await _syncReminder(
          treatmentId: diagnosisId,
          diseaseName: diseaseName,
          cropName: cropName,
          remindersActive: remindersActive,
          steps: steps,
        );

        treatments.add(TreatmentModel(
          id: diagnosisId,
          diseaseName: diseaseName,
          cropName: cropName,
          llmDiagnostico: llm.diagnostico,
          llmTratamiento: llm.tratamiento,
          llmPrevencion: llm.prevencion,
          totalSteps: steps.length,
          completedSteps: completedCount,
          remindersActive: remindersActive,
          steps: steps,
          createdAt: diagnosedAt,
        ));
      } catch (_) {
        continue;
      }
    }

    treatments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return treatments;
  }

  @override
  Future<void> markStepComplete({
    required String treatmentId,
    required String stepId,
  }) async {
    final key = 'treatment_$treatmentId';
    final existing = agendaBox.get(key);
    Map<String, dynamic> completions = {};
    if (existing != null) {
      try {
        completions = jsonDecode(existing) as Map<String, dynamic>;
      } catch (_) {}
    }
    completions[stepId] = DateTime.now().toIso8601String();
    await agendaBox.put(key, jsonEncode(completions));
  }

  @override
  Future<void> rescheduleStep({
    required String treatmentId,
    required String stepId,
    required DateTime newDate,
  }) async {
    await agendaBox.put(
      'reschedule_${treatmentId}_$stepId',
      newDate.toIso8601String(),
    );
  }

  @override
  Future<void> setRemindersActive({
    required String treatmentId,
    required bool active,
  }) async {
    await agendaBox.put('reminders_$treatmentId', active.toString());
  }

  static const _stepIds = ['step_1', 'step_2', 'step_3'];

  /// Mantiene los recordatorios del sistema alineados con el estado actual
  /// del tratamiento: cancela los de los 3 pasos fijos y, si los
  /// recordatorios estan activos y queda un paso pendiente, programa uno
  /// nuevo para el dia anterior a su fecha (8:00 a.m. hora local). Se llama
  /// en cada `getAgenda()` para que cubra automaticamente los cambios hechos
  /// por `markStepComplete` y `rescheduleStep` (ambos recargan la agenda).
  Future<void> _syncReminder({
    required String treatmentId,
    required String diseaseName,
    required String cropName,
    required bool remindersActive,
    required List<TreatmentStepModel> steps,
  }) async {
    for (final stepId in _stepIds) {
      await NotificationService.instance
          .cancel(NotificationService.stableId(treatmentId, stepId));
    }

    if (!remindersActive) return;

    TreatmentStepModel? active;
    for (final s in steps) {
      if (s.isScheduled) {
        active = s;
        break;
      }
    }
    if (active == null) return;

    final reminderDay = active.scheduledDate.subtract(const Duration(days: 1));
    final reminderTime = DateTime(
      reminderDay.year,
      reminderDay.month,
      reminderDay.day,
      8,
    );

    await NotificationService.instance.scheduleReminder(
      id: NotificationService.stableId(treatmentId, active.id),
      title: '$diseaseName en $cropName',
      body: active.title,
      whenLocal: reminderTime,
    );
  }

  /// Fecha efectiva de un paso: usa la reprogramada si existe (guardada por
  /// [rescheduleStep]), o el calculo por defecto (diagnostico +0/+7/+14 dias)
  /// si nunca se reprogramo. Compatible con datos ya existentes en Hive:
  /// si no hay override, el comportamiento es identico al de antes.
  DateTime _resolveScheduledDate(
    String treatmentId,
    String stepId,
    DateTime defaultDate,
  ) {
    final override = agendaBox.get('reschedule_${treatmentId}_$stepId');
    if (override == null) return defaultDate;
    return DateTime.tryParse(override) ?? defaultDate;
  }

  List<TreatmentStepModel> _buildSteps(
    String treatmentId,
    DateTime diagnosedAt,
    LlmResponseEntity llm,
    Map<String, dynamic> completions,
  ) {
    final step1Date = _resolveScheduledDate(
        treatmentId, 'step_1', diagnosedAt);
    final step2Date = _resolveScheduledDate(
        treatmentId, 'step_2', diagnosedAt.add(const Duration(days: 7)));
    final step3Date = _resolveScheduledDate(
        treatmentId, 'step_3', diagnosedAt.add(const Duration(days: 14)));

    // Compute raw statuses: completado or to-be-determined
    final ids = ['step_1', 'step_2', 'step_3'];
    final statuses = ids.map((id) {
      return completions.containsKey(id) ? 'completado' : 'pendiente';
    }).toList();

    // First non-completed step is "programado" (the active one)
    for (int i = 0; i < statuses.length; i++) {
      if (statuses[i] != 'completado') {
        statuses[i] = 'programado';
        break;
      }
    }

    DateTime? completedDateFor(String id) {
      final val = completions[id] as String?;
      return val != null ? DateTime.tryParse(val) : null;
    }

    final tratamiento = llm.tratamiento.length > 280
        ? '${llm.tratamiento.substring(0, 280)}...'
        : llm.tratamiento;

    final prevencion = llm.prevencion.length > 220
        ? '${llm.prevencion.substring(0, 220)}...'
        : llm.prevencion;

    return [
      TreatmentStepModel(
        id: 'step_1',
        stepNumber: 1,
        title: 'Primera aplicación',
        description: tratamiento,
        status: statuses[0],
        scheduledDate: step1Date,
        completedDate: completedDateFor('step_1'),
      ),
      TreatmentStepModel(
        id: 'step_2',
        stepNumber: 2,
        title: 'Segunda aplicación',
        description: 'Repetir el tratamiento para reforzar el control de la enfermedad.',
        status: statuses[1],
        scheduledDate: step2Date,
        completedDate: completedDateFor('step_2'),
      ),
      TreatmentStepModel(
        id: 'step_3',
        stepNumber: 3,
        title: 'Revisión y prevención',
        description: prevencion,
        status: statuses[2],
        scheduledDate: step3Date,
        completedDate: completedDateFor('step_3'),
      ),
    ];
  }
}
