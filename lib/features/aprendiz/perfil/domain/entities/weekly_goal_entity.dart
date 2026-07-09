import 'package:equatable/equatable.dart';

/// Tipo de objetivo semanal mostrado en el Perfil.
enum WeeklyGoalType { registerCrop, doDiagnosis, completeAgendaActivities }

/// Objetivo semanal del aprendiz, con avance real calculado sobre los
/// ultimos 7 dias (ver `AprendizProfileLocalDataSourceImpl`).
class WeeklyGoalEntity extends Equatable {
  final WeeklyGoalType type;
  final String label;
  final int current;
  final int target;

  const WeeklyGoalEntity({
    required this.type,
    required this.label,
    required this.current,
    required this.target,
  });

  bool get isCompleted => current >= target;

  double get progress => target <= 0 ? 0 : (current / target).clamp(0, 1);

  @override
  List<Object?> get props => [type, label, current, target];
}
