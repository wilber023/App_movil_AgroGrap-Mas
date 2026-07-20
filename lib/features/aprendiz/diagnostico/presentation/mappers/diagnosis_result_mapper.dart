import '../../../../agricultor/diagnosis/domain/entities/diagnosis_entity.dart';
import '../../../../agricultor/diagnosis/domain/entities/llm_response_entity.dart';
import '../models/diagnosis_result_view_data.dart';
import 'diagnosis_text_parser.dart';

/// Traduce `DiagnosisEntity`/`LlmResponseEntity` (contrato de la API, sin
/// cambios) al modelo de presentacion que consumen las tarjetas de
/// Resultado del Diagnostico. Todas las derivaciones son deterministas —
/// nunca se inventan datos.
abstract final class DiagnosisResultMapper {
  DiagnosisResultMapper._();

  /// Familia botanica por cultivo — mismos cultivos ya ofrecidos en el
  /// formulario de Registrar Cultivo (`aprendiz_crop_register_page.dart`).
  static const Map<String, String> _cropFamilies = {
    'calabaza': 'Cucurbitaceae',
    'frijol': 'Fabaceae',
    'maíz': 'Poaceae',
    'maiz': 'Poaceae',
    'papa': 'Solanaceae',
    'tomate': 'Solanaceae',
  };

  static const Map<DiagnosisType, List<String>> _typeKeywords = {
    DiagnosisType.fungus: ['oídio', 'oidio', 'mildiu', 'roya', 'tizón', 'tizon', 'moho', 'antracnosis', 'hongo'],
    DiagnosisType.bacteria: ['bacteria', 'bacteriana', 'marchitez bacteriana'],
    DiagnosisType.pest: ['pulgón', 'pulgon', 'mosca', 'araña', 'arana', 'trips', 'gusano', 'plaga', 'insecto'],
    DiagnosisType.virus: ['virus', 'mosaico'],
  };

  static DiagnosisResultViewData mapResult(DiagnosisEntity diagnosis) {
    final isHealthy = diagnosis.statusLabel == 'Saludable';
    final avisosCount = diagnosis.llmResponse?.avisos.length ?? 0;

    return DiagnosisResultViewData(
      imagePath: diagnosis.imagePath,
      cropName: diagnosis.cropName,
      cropFamily: _cropFamilies[diagnosis.cropName.trim().toLowerCase()],
      confidence: diagnosis.confidence,
      confidenceLevel: _confidenceLevelOf(diagnosis.confidence),
      isHealthy: isHealthy,
      diseaseName: diagnosis.diseaseName,
      diagnosisType: isHealthy ? DiagnosisType.unknown : _diagnosisTypeOf(diagnosis.diseaseName),
      severity: _severityOf(avisosCount),
    );
  }

  static DiagnosisLlmViewData mapLlmResponse(LlmResponseEntity llm) {
    return DiagnosisLlmViewData(
      whatIsHappening: llm.diagnostico.trim(),
      evidence: llm.sintomas.where((s) => s.trim().isNotEmpty).toList(),
      actions: DiagnosisTextParser.splitIntoItems(llm.tratamiento),
      prevention: DiagnosisTextParser.splitIntoItems(llm.prevencion),
      funFact: llm.aprendizaje.trim().isEmpty ? null : llm.aprendizaje.trim(),
      risks: llm.avisos.where((a) => a.trim().isNotEmpty).toList(),
    );
  }

  static ConfidenceLevel _confidenceLevelOf(double confidence) {
    if (confidence >= 0.85) return ConfidenceLevel.high;
    if (confidence >= 0.6) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  static SeverityLevel _severityOf(int avisosCount) {
    if (avisosCount >= 2) return SeverityLevel.high;
    if (avisosCount == 1) return SeverityLevel.moderate;
    return SeverityLevel.low;
  }

  static DiagnosisType _diagnosisTypeOf(String diseaseName) {
    final normalized = diseaseName.toLowerCase();
    for (final entry in _typeKeywords.entries) {
      if (entry.value.any(normalized.contains)) return entry.key;
    }
    return DiagnosisType.unknown;
  }
}
