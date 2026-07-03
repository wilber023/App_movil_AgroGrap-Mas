import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'cnn_result.dart';
import 'labels_repository.dart';

/// Softmax + Top-K sobre los logits / probabilidades del modelo.
class Postprocessing {
  Postprocessing._();

  /// [logits]   — Float32List de longitud N (salida directa del TFLite).
  /// [labelMap] — índice → LabelEntry con crop y disease ya en español.
  /// Retorna lista ordenada de mayor a menor confianza.
  static List<TopKPrediction> softmaxTopK(
    Float32List logits,
    Map<int, LabelEntry> labelMap, {
    int k = 3,
  }) {
    // Auto-detectar si el modelo ya tiene softmax horneado.
    // Si la suma es ≈1.0 y todos los valores son ≥0, ya son probabilidades.
    final rawSum = logits.fold<double>(0.0, (a, b) => a + b);
    final alreadyNormalized =
        rawSum > 0.98 && rawSum < 1.02 && logits.every((v) => v >= 0.0);

    final probs = alreadyNormalized
        ? logits.map((v) => v.toDouble()).toList()
        : _softmax(logits);

    final indexed = List.generate(probs.length, (i) => (i, probs[i]));
    indexed.sort((a, b) => b.$2.compareTo(a.$2));

    return indexed.take(k).map((pair) {
      final entry = labelMap[pair.$1] ??
          LabelEntry(
            raw: 'idx_${pair.$1}',
            crop: 'Desconocido',
            disease: 'Desconocido',
          );
      return TopKPrediction(
        rawLabel:    entry.raw,
        cropName:    entry.crop,
        diseaseName: entry.disease,
        confidence:  pair.$2,
      );
    }).toList();
  }

  static List<double> _softmax(Float32List logits) {
    double maxVal = logits[0];
    for (final v in logits) {
      if (v > maxVal) { maxVal = v; }
    }
    final exps = logits.map((v) => math.exp(v - maxVal)).toList();
    final sum = exps.fold<double>(0.0, (acc, e) => acc + e);
    return exps.map((e) => e / sum).toList();
  }
}
