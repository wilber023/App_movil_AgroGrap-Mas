import 'package:equatable/equatable.dart';

import '../../data/services/cnn_engine/cnn_result.dart';

class DiagnosisEntity extends Equatable {
  final String id;
  final String diseaseName;
  final String scientificName;
  final String cropName;
  final String? parcelName;
  final String severity;
  final double confidence;
  final String description;
  final List<String> symptoms;
  final List<String> recommendationsWhatIs;
  final List<String> recommendationsWhatToDo;
  final String recommendationsNoAction;
  final String? imagePath;
  final DateTime diagnosedAt;
  final bool isPendingSync;
  final double? treatmentProgress;
  final String? treatmentStep;
  final String statusLabel;
  // Top-K predicciones del CNN (solo se mantiene en sesión, no se persiste en Hive)
  final List<TopKPrediction> topK;

  const DiagnosisEntity({
    required this.id,
    required this.diseaseName,
    required this.scientificName,
    required this.cropName,
    this.parcelName,
    required this.severity,
    required this.confidence,
    required this.description,
    this.symptoms = const [],
    this.recommendationsWhatIs = const [],
    this.recommendationsWhatToDo = const [],
    this.recommendationsNoAction = '',
    this.imagePath,
    required this.diagnosedAt,
    this.isPendingSync = false,
    this.treatmentProgress,
    this.treatmentStep,
    required this.statusLabel,
    this.topK = const [],
  });

  @override
  List<Object?> get props => [
        id,
        diseaseName,
        cropName,
        parcelName,
        severity,
        confidence,
        isPendingSync,
        statusLabel,
      ];
}
