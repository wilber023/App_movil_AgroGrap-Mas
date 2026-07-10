import 'package:equatable/equatable.dart';

/// Resumen del cultivo activo para la tarjeta "Estado del cultivo".
/// `hasCropPlan = false` cuando el usuario todavia no registra un cultivo.
class CropStatusSummaryEntity extends Equatable {
  final bool hasCropPlan;
  final String? cropName;
  final DateTime? lastUpdate;
  final String? lastDiagnosisLabel;

  /// Semana actual dentro del plan (real, `CropPlanEntity.currentWeek`).
  final int? currentWeek;

  /// Progreso del ciclo 0-100 (real, `CropPlanEntity.progressPercentage`).
  final double? progressPercentage;

  /// Etapa actual tal cual la reporta el backend (real, `CropPlanEntity.currentStage`).
  final String? stageLabel;

  /// Indice 0-4 de la etapa actual dentro de la secuencia generica de
  /// crecimiento (Siembra/Crecimiento/Floración/Fruto/Cosecha), derivado por
  /// coincidencia de palabras clave sobre [stageLabel] o, si no hay
  /// coincidencia, por [progressPercentage]. Nunca inventa una etapa que el
  /// backend no reporte — solo ubica la real dentro de esta escala visual.
  final int? stageIndex;

  /// Estado de salud del cultivo (real, `CropHealthEntity.status`:
  /// 'Saludable' | 'En Riesgo' | 'Crítico'). Null si aun no hay indicador.
  final String? healthStatus;

  const CropStatusSummaryEntity({
    required this.hasCropPlan,
    this.cropName,
    this.lastUpdate,
    this.lastDiagnosisLabel,
    this.currentWeek,
    this.progressPercentage,
    this.stageLabel,
    this.stageIndex,
    this.healthStatus,
  });

  static const empty = CropStatusSummaryEntity(hasCropPlan: false);

  @override
  List<Object?> get props => [
        hasCropPlan,
        cropName,
        lastUpdate,
        lastDiagnosisLabel,
        currentWeek,
        progressPercentage,
        stageLabel,
        stageIndex,
        healthStatus,
      ];
}
