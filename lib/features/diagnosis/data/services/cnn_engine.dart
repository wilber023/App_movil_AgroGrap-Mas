import 'package:flutter/foundation.dart';

import 'cnn_engine/agricultural_knowledge_base.dart';
import 'cnn_engine/cnn_result.dart';
import 'cnn_engine/labels_repository.dart';
import 'cnn_engine/postprocessing.dart';
import 'cnn_engine/preprocessing.dart';
import 'cnn_engine/tflite_runner.dart';

export 'cnn_engine/cnn_result.dart';

// =============================================================================
// AgroGraph-MAS — Motor CNN Real (TFLite + EfficientNet-B4)
// Pipeline: imagen → preprocessing isolate → TFLite → softmax → top-K
// Basado en best.pth (50 clases, accuracy 96.69%, class_mapping extraído)
// =============================================================================

class CnnEngine {
  CnnEngine._();

  /// Analiza una imagen y retorna el resultado real del modelo CNN.
  ///
  /// Lanza [StateError] si el modelo no está disponible (best.tflite no existe).
  /// Lanza [Exception] si la imagen no puede ser leída.
  static Future<CnnResult> analyze(String imagePath) async {
    // 1. Cargar etiquetas si no están cargadas
    await LabelsRepository.instance.load();

    // 2. Inicializar el modelo TFLite si no está listo
    await GlobalModelManager.instance.initialize();

    // 3. Preprocesar imagen en un isolate (no bloquea la UI)
    //    Resultado: Float32List [380×380×3] NHWC, ImageNet-normalizado
    final inputTensor = await compute(preprocessImageIsolate, imagePath);

    // 4. Inferencia TFLite en el hilo principal (donde vive el Interpreter)
    final logits = GlobalModelManager.instance.runInference(inputTensor);

    // 5. Softmax + Top-3
    final topK = Postprocessing.softmaxTopK(
      logits,
      LabelsRepository.instance.labelMap,
      k: 3,
    );

    // 6. Enriquecer resultado con base de conocimiento agrícola
    final top = topK.first;
    final info = AgriculturalKnowledgeBase.lookup(top.rawLabel);

    return CnnResult(
      cropName: info.cropName,
      diseaseName: info.diseaseName,
      scientificName: info.scientificName,
      severity: info.severity,
      confidence: top.confidence,
      topK: topK,
      whatIs: info.whatIs,
      whatToDo: info.whatToDo,
      ifNoAction: info.ifNoAction,
    );
  }
}
