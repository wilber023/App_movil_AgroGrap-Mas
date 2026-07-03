import 'package:equatable/equatable.dart';

import '../../data/services/cnn_engine/cnn_result.dart';
import 'llm_response_entity.dart';

class DiagnosisEntity extends Equatable {
  final String id;
  final String diseaseName;
  final String cropName;
  final double confidence;
  final String? imagePath;
  final DateTime diagnosedAt;
  final bool isPendingSync;
  final double? treatmentProgress;
  final String? treatmentStep;
  final String statusLabel;
  // Top-K predicciones del CNN (solo vive en sesión, no se persiste en Hive)
  final List<TopKPrediction> topK;
  // Respuesta del LLM/RAG (se persiste en Hive tras la primera consulta)
  final LlmResponseEntity? llmResponse;
  // Contexto de parcela (opcional — solo cuando el diagnóstico se inicia desde una parcela)
  final String? parcelId;
  final String? parcelName;

  const DiagnosisEntity({
    required this.id,
    required this.diseaseName,
    required this.cropName,
    required this.confidence,
    this.imagePath,
    required this.diagnosedAt,
    this.isPendingSync = false,
    this.treatmentProgress,
    this.treatmentStep,
    required this.statusLabel,
    this.topK = const [],
    this.llmResponse,
    this.parcelId,
    this.parcelName,
  });

  @override
  List<Object?> get props => [
        id,
        diseaseName,
        cropName,
        confidence,
        isPendingSync,
        statusLabel,
      ];
}
