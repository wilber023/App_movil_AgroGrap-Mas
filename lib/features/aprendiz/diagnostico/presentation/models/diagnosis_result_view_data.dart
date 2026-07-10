/// Modelo de presentacion (ViewModel) para la pantalla de Resultado del
/// Diagnostico. Puro Dart — no depende de Flutter ni de ningun paquete de
/// UI. Lo produce `DiagnosisResultMapper` a partir de `DiagnosisEntity` +
/// `LlmResponseEntity` (que no cambian: son el contrato de la API). Los
/// widgets traducen estos campos/enums a `AppColors`/`AppTypography`.
library;

/// Nivel de confianza del reconocimiento de la planta/enfermedad.
enum ConfidenceLevel { high, medium, low }

/// Severidad del diagnostico, derivada de `avisos.length` (ver mapper).
enum SeverityLevel { low, moderate, high }

/// Tipo de agente causante, inferido por palabras clave del nombre de la
/// enfermedad (ver mapper). No viene en el contrato de la API.
enum DiagnosisType { fungus, bacteria, pest, virus, unknown }

class DiagnosisResultViewData {
  final String? imagePath;

  final String cropName;
  final String? cropFamily;
  final double confidence;
  final ConfidenceLevel confidenceLevel;

  final bool isHealthy;
  final String diseaseName;
  final DiagnosisType diagnosisType;
  final SeverityLevel severity;

  const DiagnosisResultViewData({
    required this.imagePath,
    required this.cropName,
    required this.cropFamily,
    required this.confidence,
    required this.confidenceLevel,
    required this.isHealthy,
    required this.diseaseName,
    required this.diagnosisType,
    required this.severity,
  });
}

/// Contenido derivado de `LlmResponseEntity`, disponible solo cuando el
/// LLM ya respondio (`LlmDiagnosisLoaded`).
class DiagnosisLlmViewData {
  final String whatIsHappening;
  final List<String> evidence;
  final List<String> actions;
  final List<String> prevention;
  final String? funFact;
  final List<String> risks;

  const DiagnosisLlmViewData({
    required this.whatIsHappening,
    required this.evidence,
    required this.actions,
    required this.prevention,
    required this.funFact,
    required this.risks,
  });
}
