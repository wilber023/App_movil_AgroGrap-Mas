import '../../domain/entities/diagnosis_entity.dart';

class DiagnosisModel extends DiagnosisEntity {
  const DiagnosisModel({
    required super.id,
    required super.cropName,
    required super.diseaseName,
    required super.severity,
    required super.confidence,
    required super.description,
    super.symptoms,
    super.recommendations,
    super.imageUrl,
    required super.diagnosedAt,
    super.parcelName,
  });

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      id: json['id'] as String? ?? '',
      cropName: json['crop_name'] as String? ?? '',
      diseaseName: json['disease_name'] as String? ?? '',
      severity: json['severity'] as String? ?? 'baja',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      imageUrl: json['image_url'] as String?,
      diagnosedAt: DateTime.tryParse(json['diagnosed_at'] as String? ?? '') ??
          DateTime.now(),
      parcelName: json['parcel_name'] as String? ?? '',
    );
  }
}

class DiagnosisHistoryItemModel extends DiagnosisHistoryItem {
  const DiagnosisHistoryItemModel({
    required super.id,
    required super.cropName,
    required super.diseaseName,
    required super.severity,
    required super.diagnosedAt,
    super.thumbnailUrl,
  });

  factory DiagnosisHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisHistoryItemModel(
      id: json['id'] as String? ?? '',
      cropName: json['crop_name'] as String? ?? '',
      diseaseName: json['disease_name'] as String? ?? '',
      severity: json['severity'] as String? ?? 'baja',
      diagnosedAt: DateTime.tryParse(json['diagnosed_at'] as String? ?? '') ??
          DateTime.now(),
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
}
