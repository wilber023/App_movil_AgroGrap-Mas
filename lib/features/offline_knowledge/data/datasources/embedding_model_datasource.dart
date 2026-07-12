// =============================================================================
// AgroGraph-MAS — EmbeddingModelDataSource (offline_knowledge)
// Wrapper del modelo de embeddings on-device (mismo rol que GlobalModelManager
// en features/agricultor/diagnosis/data/services/cnn_engine/tflite_runner.dart
// para la CNN de diagnóstico).
// =============================================================================

import 'dart:math' as math;

/// Vectoriza texto libre para el fallback semántico (ver sección 6 del
/// documento de especificación). Dimensión esperada del vector: 384
/// (paraphrase-multilingual-MiniLM-L12-v2, ver sección 8).
abstract interface class EmbeddingModelDataSource {
  Future<List<double>> encode(String text);
}

/// Implementación placeholder: el modelo `.tflite` real todavía no está
/// empaquetado en `assets/models/` (fuera de alcance de este sprint, ver
/// sección 11). Mientras tanto genera un embedding determinístico
/// (mismo texto → mismo vector) para no bloquear el resto del flujo de
/// fallback semántico ni el resto de la app con un asset inexistente.
class EmbeddingModelDataSourceImpl implements EmbeddingModelDataSource {
  static const int embeddingDim = 384;

  @override
  Future<List<double>> encode(String text) async {
    // TODO: reemplazar con modelo real cuando esté disponible.
    // Seguir el mismo patrón que GlobalModelManager (tflite_runner.dart):
    // cargar con `Interpreter.fromAsset('assets/models/embedding_model.tflite')`,
    // tokenizar `text` y ejecutar la inferencia aquí.
    return _placeholderEmbedding(text);
  }

  List<double> _placeholderEmbedding(String text) {
    final rnd = math.Random(text.hashCode);
    return List<double>.generate(embeddingDim, (_) => rnd.nextDouble() * 2 - 1);
  }
}
