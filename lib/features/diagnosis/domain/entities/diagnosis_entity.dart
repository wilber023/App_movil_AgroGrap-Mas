import 'package:equatable/equatable.dart';

class DiagnosisEntity extends Equatable {
  final String id;
  final String cropName;
  final String diseaseName;
  final String severity; // alta, media, baja
  final double confidence;
  final String description;
  final List<String> symptoms;
  final List<String> recommendations;
  final String? imageUrl;
  final DateTime diagnosedAt;
  final String parcelName;

  const DiagnosisEntity({
    required this.id,
    required this.cropName,
    required this.diseaseName,
    required this.severity,
    required this.confidence,
    required this.description,
    this.symptoms = const [],
    this.recommendations = const [],
    this.imageUrl,
    required this.diagnosedAt,
    this.parcelName = '',
  });

  bool get isHighSeverity => severity.toLowerCase() == 'alta';

  @override
  List<Object?> get props => [id, cropName, diseaseName, severity, confidence];
}

class DiagnosisHistoryItem extends Equatable {
  final String id;
  final String cropName;
  final String diseaseName;
  final String severity;
  final DateTime diagnosedAt;
  final String? thumbnailUrl;

  const DiagnosisHistoryItem({
    required this.id,
    required this.cropName,
    required this.diseaseName,
    required this.severity,
    required this.diagnosedAt,
    this.thumbnailUrl,
  });

  @override
  List<Object?> get props => [id, cropName, diseaseName, severity];
}
