import 'dart:convert';

import '../../../../agricultor/diagnosis/domain/entities/diagnosis_entity.dart';
import '../../../../agricultor/diagnosis/domain/entities/llm_response_entity.dart';

/// Modelo de persistencia del diagnóstico del Aprendiz en SQLite.
///
/// Extiende [DiagnosisEntity] (compartida con el perfil Agricultor) y añade
/// el mapeo hacia/desde una fila de la tabla `aprendiz_diagnoses`.
class AprendizDiagnosisModel extends DiagnosisEntity {
  /// Usuario autenticado dueño del registro — clave de aislamiento por perfil.
  final String? userId;

  const AprendizDiagnosisModel({
    required super.id,
    required this.userId,
    required super.diseaseName,
    required super.cropName,
    required super.confidence,
    super.imagePath,
    required super.diagnosedAt,
    super.isPendingSync,
    required super.statusLabel,
    super.llmResponse,
    super.parcelId,
    super.parcelName,
  });

  factory AprendizDiagnosisModel.fromEntity(DiagnosisEntity entity, {required String? userId}) {
    return AprendizDiagnosisModel(
      id: entity.id,
      userId: userId,
      diseaseName: entity.diseaseName,
      cropName: entity.cropName,
      confidence: entity.confidence,
      imagePath: entity.imagePath,
      diagnosedAt: entity.diagnosedAt,
      isPendingSync: entity.isPendingSync,
      statusLabel: entity.statusLabel,
      llmResponse: entity.llmResponse,
      parcelId: entity.parcelId,
      parcelName: entity.parcelName,
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'user_id': userId,
      'disease_name': diseaseName,
      'crop_name': cropName,
      'confidence': confidence,
      'image_path': imagePath,
      'diagnosed_at': diagnosedAt.toIso8601String(),
      'is_pending_sync': isPendingSync ? 1 : 0,
      'status_label': statusLabel,
      'parcel_id': parcelId,
      'parcel_name': parcelName,
      'llm_response_json': llmResponse != null ? encodeLlmResponse(llmResponse!) : null,
    };
  }

  factory AprendizDiagnosisModel.fromRow(Map<String, Object?> row) {
    final llmJson = row['llm_response_json'] as String?;
    return AprendizDiagnosisModel(
      id: row['id'] as String? ?? '',
      userId: row['user_id'] as String?,
      diseaseName: row['disease_name'] as String? ?? '',
      cropName: row['crop_name'] as String? ?? '',
      confidence: (row['confidence'] as num?)?.toDouble() ?? 0.0,
      imagePath: row['image_path'] as String?,
      diagnosedAt: DateTime.tryParse(row['diagnosed_at'] as String? ?? '') ?? DateTime.now(),
      isPendingSync: (row['is_pending_sync'] as int? ?? 0) == 1,
      statusLabel: row['status_label'] as String? ?? 'Seguimiento',
      parcelId: row['parcel_id'] as String?,
      parcelName: row['parcel_name'] as String?,
      llmResponse: llmJson != null ? decodeLlmResponse(llmJson) : null,
    );
  }

  static String encodeLlmResponse(LlmResponseEntity r) => jsonEncode(r.toJson());

  static LlmResponseEntity decodeLlmResponse(String json) =>
      LlmResponseEntity.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
