import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/diagnosis_entity.dart';
import '../../domain/entities/llm_response_entity.dart';

/// Persistencia local (Hive) del historial de diagnósticos, extraída de
/// [DiagnosisBloc] para separar la serialización/almacenamiento de la
/// orquestación de eventos. Sin cambios de comportamiento: mismo formato
/// JSON, misma caja Hive.
class DiagnosisHistoryStorage {
  final Box<String> _historyBox;
  const DiagnosisHistoryStorage(this._historyBox);

  Future<void> persist(DiagnosisEntity entity) async {
    try {
      final encoded = jsonEncode({
        'id': entity.id,
        'diseaseName': entity.diseaseName,
        'cropName': entity.cropName,
        'confidence': entity.confidence,
        'imagePath': entity.imagePath,
        'diagnosedAt': entity.diagnosedAt.toIso8601String(),
        'isPendingSync': entity.isPendingSync,
        'statusLabel': entity.statusLabel,
        if (entity.parcelId != null) 'parcelId': entity.parcelId,
        if (entity.parcelName != null) 'parcelName': entity.parcelName,
        // topK no se persiste (solo vive en sesión)
      });
      await _historyBox.add(encoded);
    } catch (e) {
      debugPrint('[DiagnosisHistoryStorage] Error al persistir en Hive: $e');
    }
  }

  List<DiagnosisEntity> loadAll() {
    final items = <DiagnosisEntity>[];
    for (final raw in _historyBox.values) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        items.add(_mapToEntity(m));
      } catch (e) {
        debugPrint('[DiagnosisHistoryStorage] Error al deserializar historial: $e');
      }
    }
    return items.reversed.toList();
  }

  /// Persiste la respuesta LLM en la entrada de Hive del diagnóstico indicado.
  Future<void> saveLlmResponse({
    required String diagnosisId,
    required LlmResponseEntity llmResponse,
  }) async {
    for (final key in _historyBox.keys) {
      final raw = _historyBox.get(key);
      if (raw == null) continue;
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        if (m['id'] == diagnosisId) {
          m['llmResponse'] = llmResponse.toJson();
          await _historyBox.put(key, jsonEncode(m));
          return;
        }
      } catch (e) {
        debugPrint('[DiagnosisHistoryStorage] Error al guardar LLM en Hive: $e');
      }
    }
  }

  DiagnosisEntity _mapToEntity(Map<String, dynamic> m) {
    final llmJson = m['llmResponse'] as Map<String, dynamic>?;
    return DiagnosisEntity(
      id: m['id'] as String? ?? '',
      diseaseName: m['diseaseName'] as String? ?? '',
      cropName: m['cropName'] as String? ?? '',
      confidence: (m['confidence'] as num?)?.toDouble() ?? 0.0,
      imagePath: m['imagePath'] as String?,
      diagnosedAt:
          DateTime.tryParse(m['diagnosedAt'] as String? ?? '') ?? DateTime.now(),
      isPendingSync: m['isPendingSync'] as bool? ?? false,
      statusLabel: m['statusLabel'] as String? ?? 'Seguimiento',
      // topK vacío en historial persistido (no se guarda)
      llmResponse:
          llmJson != null ? LlmResponseEntity.fromJson(llmJson) : null,
      parcelId: m['parcelId'] as String?,
      parcelName: m['parcelName'] as String?,
    );
  }
}
