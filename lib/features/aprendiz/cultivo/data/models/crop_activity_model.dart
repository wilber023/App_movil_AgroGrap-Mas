import '../../domain/entities/crop_activity_entity.dart';

class CropActivityModel extends CropActivityEntity {
  const CropActivityModel({
    required super.id,
    required super.title,
    required super.description,
    required super.weekNumber,
    required super.status,
    required super.scheduledDate,
    super.isPendingSync,
  });

  factory CropActivityModel.fromJson(Map<String, dynamic> json) {
    return CropActivityModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      weekNumber: json['weekNumber'],
      status: ActivityStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ActivityStatus.pending,
      ),
      scheduledDate: DateTime.parse(json['scheduledDate']),
      isPendingSync: json['isPendingSync'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'weekNumber': weekNumber,
      'status': status.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      'isPendingSync': isPendingSync,
    };
  }

  factory CropActivityModel.fromEntity(CropActivityEntity entity) {
    return CropActivityModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      weekNumber: entity.weekNumber,
      status: entity.status,
      scheduledDate: entity.scheduledDate,
      isPendingSync: entity.isPendingSync,
    );
  }
}
