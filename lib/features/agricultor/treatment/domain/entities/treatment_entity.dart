import 'package:equatable/equatable.dart';

class TreatmentEntity extends Equatable {
  final String id;
  final String diseaseName;
  final String cropName;
  final String llmDiagnostico;
  final String llmTratamiento;
  final String llmPrevencion;
  final int totalSteps;
  final int completedSteps;
  final bool remindersActive;
  final List<TreatmentStepEntity> steps;
  final DateTime createdAt;

  const TreatmentEntity({
    required this.id,
    required this.diseaseName,
    required this.cropName,
    this.llmDiagnostico = '',
    this.llmTratamiento = '',
    this.llmPrevencion = '',
    required this.totalSteps,
    required this.completedSteps,
    this.remindersActive = true,
    this.steps = const [],
    required this.createdAt,
  });

  double get progress =>
      totalSteps > 0 ? completedSteps / totalSteps : 0.0;

  int get progressPercent => (progress * 100).toInt();

  /// Paso pendiente actual (el primero no completado). Null si ya no queda
  /// ningun paso por hacer (tratamiento completado al 100%).
  TreatmentStepEntity? get activeStep {
    for (final step in steps) {
      if (step.isScheduled) return step;
    }
    return null;
  }

  bool get isOverdue => activeStep?.isOverdue ?? false;
  bool get isDueToday => activeStep?.isDueToday ?? false;
  bool get isDueThisWeek => activeStep?.isDueThisWeek ?? false;

  @override
  List<Object?> get props =>
      [id, diseaseName, totalSteps, completedSteps, remindersActive];
}

class TreatmentStepEntity extends Equatable {
  final String id;
  final int stepNumber;
  final String title;
  final String description;
  final String status; // completado, programado, pendiente
  final DateTime scheduledDate;
  final DateTime? completedDate;

  const TreatmentStepEntity({
    required this.id,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.scheduledDate,
    this.completedDate,
  });

  bool get isCompleted => status == 'completado';
  bool get isScheduled => status == 'programado';

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Vencido: sigue "programado" y su fecha ya paso (dia calendario, no hora).
  bool get isOverdue {
    if (!isScheduled) return false;
    return _dateOnly(scheduledDate).isBefore(_dateOnly(DateTime.now()));
  }

  /// Dias de atraso respecto a hoy. 0 si no esta vencido.
  int get daysOverdue {
    if (!isOverdue) return 0;
    return _dateOnly(DateTime.now()).difference(_dateOnly(scheduledDate)).inDays;
  }

  /// Vence exactamente hoy.
  bool get isDueToday {
    if (!isScheduled) return false;
    return _dateOnly(scheduledDate) == _dateOnly(DateTime.now());
  }

  /// Vence entre hoy y los proximos 7 dias (inclusive), sin contar atrasados.
  bool get isDueThisWeek {
    if (!isScheduled) return false;
    final diff = _dateOnly(scheduledDate).difference(_dateOnly(DateTime.now())).inDays;
    return diff >= 0 && diff <= 7;
  }

  @override
  List<Object?> get props => [id, stepNumber, status];
}
