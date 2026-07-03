import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../diagnosis/domain/entities/llm_response_entity.dart';
import '../models/treatment_model.dart';

abstract interface class TreatmentLocalDataSource {
  Future<List<TreatmentModel>> getAgenda();
  Future<void> markStepComplete({
    required String treatmentId,
    required String stepId,
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

        final steps = _buildSteps(diagnosedAt, llm, completions);
        final completedCount = steps.where((s) => s.isCompleted).length;

        treatments.add(TreatmentModel(
          id: diagnosisId,
          diseaseName: m['diseaseName'] as String? ?? '',
          cropName: m['cropName'] as String? ?? '',
          llmDiagnostico: llm.diagnostico,
          llmTratamiento: llm.tratamiento,
          llmPrevencion: llm.prevencion,
          totalSteps: steps.length,
          completedSteps: completedCount,
          remindersActive: true,
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

  List<TreatmentStepModel> _buildSteps(
    DateTime diagnosedAt,
    LlmResponseEntity llm,
    Map<String, dynamic> completions,
  ) {
    final step1Date = diagnosedAt;
    final step2Date = diagnosedAt.add(const Duration(days: 7));
    final step3Date = diagnosedAt.add(const Duration(days: 14));

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
