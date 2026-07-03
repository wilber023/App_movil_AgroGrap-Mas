/// Un resultado individual del Top-K del CNN.
class TopKPrediction {
  final String rawLabel;
  final String cropName;
  final String diseaseName;
  final double confidence;

  const TopKPrediction({
    required this.rawLabel,
    required this.cropName,
    required this.diseaseName,
    required this.confidence,
  });
}

/// Resultado de una inferencia CNN real (solo lo que el modelo produce).
class CnnResult {
  final String cropName;
  final String diseaseName;
  final double confidence;
  final List<TopKPrediction> topK;

  const CnnResult({
    required this.cropName,
    required this.diseaseName,
    required this.confidence,
    required this.topK,
  });
}
