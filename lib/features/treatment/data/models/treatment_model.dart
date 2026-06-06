import '../../domain/entities/treatment_entity.dart';

class TreatmentModel extends TreatmentEntity {
  const TreatmentModel({
    required super.id,
    required super.diseaseName,
    required super.cropName,
    required super.totalSteps,
    required super.completedSteps,
    super.remindersActive,
    super.steps,
    required super.createdAt,
  });

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    return TreatmentModel(
      id: json['id'] as String? ?? '',
      diseaseName: json['disease_name'] as String? ?? '',
      cropName: json['crop_name'] as String? ?? '',
      totalSteps: json['total_steps'] as int? ?? 0,
      completedSteps: json['completed_steps'] as int? ?? 0,
      remindersActive: json['reminders_active'] as bool? ?? true,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) =>
                  TreatmentStepModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class TreatmentStepModel extends TreatmentStepEntity {
  const TreatmentStepModel({
    required super.id,
    required super.stepNumber,
    required super.title,
    required super.description,
    required super.status,
    required super.scheduledDate,
    super.completedDate,
  });

  factory TreatmentStepModel.fromJson(Map<String, dynamic> json) {
    return TreatmentStepModel(
      id: json['id'] as String? ?? '',
      stepNumber: json['step_number'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'pendiente',
      scheduledDate:
          DateTime.tryParse(json['scheduled_date'] as String? ?? '') ??
              DateTime.now(),
      completedDate: json['completed_date'] != null
          ? DateTime.tryParse(json['completed_date'] as String)
          : null,
    );
  }
}
