import 'package:equatable/equatable.dart';

class TreatmentEntity extends Equatable {
  final String id;
  final String diseaseName;
  final String cropName;
  final int totalSteps;
  final int completedSteps;
  final bool remindersActive;
  final List<TreatmentStepEntity> steps;
  final DateTime createdAt;

  const TreatmentEntity({
    required this.id,
    required this.diseaseName,
    required this.cropName,
    required this.totalSteps,
    required this.completedSteps,
    this.remindersActive = true,
    this.steps = const [],
    required this.createdAt,
  });

  double get progress =>
      totalSteps > 0 ? completedSteps / totalSteps : 0.0;

  int get progressPercent => (progress * 100).toInt();

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

  @override
  List<Object?> get props => [id, stepNumber, status];
}
