import '../../domain/entities/crop_plan_entity.dart';
import 'crop_activity_model.dart';

class CropPlanModel extends CropPlanEntity {
  const CropPlanModel({
    required super.id,
    required super.userId,
    required super.cropName,
    required super.currentStage,
    required super.startDate,
    required super.currentWeek,
    required super.progressPercentage,
    required super.activities,
    super.isPendingSync,
  });

  factory CropPlanModel.fromJson(Map<String, dynamic> json) {
    return CropPlanModel(
      id: json['id'],
      userId: json['userId'],
      cropName: json['cropName'],
      currentStage: json['currentStage'],
      startDate: DateTime.parse(json['startDate']),
      currentWeek: json['currentWeek'],
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
      activities: (json['activities'] as List<dynamic>?)
              ?.map((e) => CropActivityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isPendingSync: json['isPendingSync'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'cropName': cropName,
      'currentStage': currentStage,
      'startDate': startDate.toIso8601String(),
      'currentWeek': currentWeek,
      'progressPercentage': progressPercentage,
      'activities': activities
          .map((a) => CropActivityModel.fromEntity(a).toJson())
          .toList(),
      'isPendingSync': isPendingSync,
    };
  }
}
