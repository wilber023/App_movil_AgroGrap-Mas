import 'package:equatable/equatable.dart';

/// Resumen de actividad del usuario dentro de AgroGraph, calculado a partir
/// de datos reales de Cultivo y Diagnostico (ver `AprendizProfileLocalDataSourceImpl`).
class AprendizActivitySummaryEntity extends Equatable {
  final int cropsRegistered;
  final int diagnosesCompleted;
  final int activitiesCompleted;
  final int daysLearning;

  const AprendizActivitySummaryEntity({
    required this.cropsRegistered,
    required this.diagnosesCompleted,
    required this.activitiesCompleted,
    required this.daysLearning,
  });

  @override
  List<Object?> get props => [cropsRegistered, diagnosesCompleted, activitiesCompleted, daysLearning];
}
