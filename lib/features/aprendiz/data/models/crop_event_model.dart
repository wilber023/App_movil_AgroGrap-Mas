import '../../domain/entities/crop_event_entity.dart';

class CropEventModel extends CropEventEntity {
  const CropEventModel({
    required super.id,
    required super.type,
    required super.title,
    required super.description,
    required super.date,
    super.relatedActivityId,
  });

  factory CropEventModel.fromJson(Map<String, dynamic> json) {
    return CropEventModel(
      id: json['id'],
      type: CropEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CropEventType.inspeccionSinPatologia, // fallback
      ),
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      relatedActivityId: json['relatedActivityId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'relatedActivityId': relatedActivityId,
    };
  }

  factory CropEventModel.fromEntity(CropEventEntity entity) {
    return CropEventModel(
      id: entity.id,
      type: entity.type,
      title: entity.title,
      description: entity.description,
      date: entity.date,
      relatedActivityId: entity.relatedActivityId,
    );
  }
}
