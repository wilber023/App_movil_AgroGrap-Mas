import 'package:equatable/equatable.dart';

class CropHealthEntity extends Equatable {
  final String status; // 'Saludable', 'En Riesgo', 'Crítico'
  final int healthyPlantsPercentage;
  final int affectedPlantsPercentage;
  final DateTime lastInspectionDate;

  const CropHealthEntity({
    required this.status,
    required this.healthyPlantsPercentage,
    required this.affectedPlantsPercentage,
    required this.lastInspectionDate,
  });

  @override
  List<Object?> get props => [
        status,
        healthyPlantsPercentage,
        affectedPlantsPercentage,
        lastInspectionDate,
      ];
}
