import 'package:equatable/equatable.dart';
import 'crop_activity_entity.dart';

class CropPlanEntity extends Equatable {
  final String id;
  final String userId;
  final String cropName;
  final String currentStage; // e.g., 'Crecimiento', 'Floración'
  final DateTime startDate;
  final int currentWeek;
  final double progressPercentage;
  final List<CropActivityEntity> activities;
  final bool isPendingSync; // for offline-first

  const CropPlanEntity({
    required this.id,
    required this.userId,
    required this.cropName,
    required this.currentStage,
    required this.startDate,
    required this.currentWeek,
    required this.progressPercentage,
    required this.activities,
    this.isPendingSync = false,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        cropName,
        currentStage,
        startDate,
        currentWeek,
        progressPercentage,
        activities,
        isPendingSync,
      ];
}
