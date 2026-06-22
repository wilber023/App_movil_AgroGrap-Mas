import 'dart:math' as math;
import 'dart:typed_data';
import 'cnn_result.dart';
import 'agricultural_knowledge_base.dart';

/// Softmax + Top-K sobre los logits crudos del modelo.
class Postprocessing {
  Postprocessing._();

  /// [logits] — Float32List de longitud N (salida directa del TFLite).
  /// [labelMap] — índice → etiqueta CNN (e.g. "Tomato___Early_blight").
  /// Retorna lista ordenada de mayor a menor confianza.
  static List<TopKPrediction> softmaxTopK(
    Float32List logits,
    Map<int, String> labelMap, {
    int k = 3,
  }) {
    final probs = _softmax(logits);

    // Crear lista de (índice, probabilidad) y ordenar descendente
    final indexed = List.generate(probs.length, (i) => (i, probs[i]));
    indexed.sort((a, b) => b.$2.compareTo(a.$2));

    final topK = indexed.take(k).map((pair) {
      final rawLabel = labelMap[pair.$1] ?? 'Unknown_${pair.$1}';
      final info = AgriculturalKnowledgeBase.lookup(rawLabel);
      return TopKPrediction(
        rawLabel: rawLabel,
        cropName: info.cropName,
        diseaseName: info.diseaseName,
        confidence: pair.$2,
      );
    }).toList();

    return topK;
  }

  static List<double> _softmax(Float32List logits) {
    double maxVal = logits[0];
    for (final v in logits) {
      if (v > maxVal) maxVal = v;
    }
    final exps = logits.map((v) => math.exp(v - maxVal)).toList();
    final sum = exps.fold<double>(0.0, (acc, e) => acc + e);
    return exps.map((e) => e / sum).toList();
  }
}
