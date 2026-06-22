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

/// Resultado completo de una inferencia CNN real.
class CnnResult {
  final String cropName;
  final String diseaseName;
  final String scientificName;
  final String severity;
  final double confidence;
  final List<TopKPrediction> topK;
  final List<String> whatIs;
  final List<String> whatToDo;
  final String ifNoAction;

  const CnnResult({
    required this.cropName,
    required this.diseaseName,
    required this.scientificName,
    required this.severity,
    required this.confidence,
    required this.topK,
    required this.whatIs,
    required this.whatToDo,
    required this.ifNoAction,
  });
}
