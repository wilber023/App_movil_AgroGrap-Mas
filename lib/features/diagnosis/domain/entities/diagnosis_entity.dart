import 'package:equatable/equatable.dart';

class DiagnosisEntity extends Equatable {
  final String id;
  final String diseaseName;
  final String scientificName;
  final String cropName;
  final String? parcelName;
  final String severity; // Critica, Moderada, Leve, Saludable
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
  final String statusLabel; // En tratamiento, Seguimiento, Completado, etc.

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
