import 'package:flutter/foundation.dart';

import 'cnn_engine/cnn_result.dart';
import 'cnn_engine/labels_repository.dart';
import 'cnn_engine/postprocessing.dart';
import 'cnn_engine/preprocessing.dart';
import 'cnn_engine/tflite_runner.dart';

export 'cnn_engine/cnn_result.dart';

// =============================================================================
// AgroGraph-MAS — Motor CNN Real (TFLite + MobileNetV3-Large)
// Pipeline: imagen → preprocessing isolate → TFLite → softmax → top-K
// El modelo detecta cultivo + enfermedad directamente desde el rawLabel.
// =============================================================================

class CnnEngine {
  CnnEngine._();

  /// Analiza una imagen y retorna el resultado directo del modelo CNN.
  ///
  /// Lanza [StateError] si el modelo no está disponible (best.tflite no existe).
  /// Lanza [Exception] si la imagen no puede ser leída.
  static Future<CnnResult> analyze(String imagePath) async {
    // 1. Cargar class_mapping si no está cargado
    await LabelsRepository.instance.load();

    // 2. Inicializar el modelo TFLite si no está listo
    await GlobalModelManager.instance.initialize();

    // 3. Preprocesar imagen en isolate (no bloquea la UI)
    //    → Float32List NCHW [1×3×224×224], normalizado ImageNet
    final inputTensor = await compute(preprocessImageIsolate, imagePath);

    // 4. Inferencia TFLite en el hilo principal (donde vive el Interpreter)
    final logits = GlobalModelManager.instance.runInference(inputTensor);

    // 5. Softmax + Top-3: parsea rawLabel "Cultivo__Enfermedad" directamente
    final topK = Postprocessing.softmaxTopK(
      logits,
      LabelsRepository.instance.labelMap,
      k: 3,
    );

    final top = topK.first;
    return CnnResult(
      cropName: top.cropName,
      diseaseName: top.diseaseName,
      confidence: top.confidence,
      topK: topK,
    );
  }
}
