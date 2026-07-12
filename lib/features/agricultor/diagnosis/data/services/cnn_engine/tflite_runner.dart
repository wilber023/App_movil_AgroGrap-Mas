import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

const int _kImgSize = 224;

/// Singleton que gestiona el ciclo de vida del intérprete TFLite.
class GlobalModelManager {
  GlobalModelManager._();
  static final GlobalModelManager instance = GlobalModelManager._();

  Interpreter? _interpreter;
  bool _loading = false;
  String? _lastError;

  bool get isReady => _interpreter != null;
  String? get lastError => _lastError;

  Future<void> initialize() async {
    if (_interpreter != null) return;
    if (_loading) {
      while (_loading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_interpreter == null) {
        throw StateError(_lastError ?? 'Modelo CNN no disponible');
      }
      return;
    }

    _loading = true;
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/best.tflite',
        options: options,
      );
      _interpreter!.allocateTensors();

      final inShape  = _interpreter!.getInputTensor(0).shape;
      final outShape = _interpreter!.getOutputTensor(0).shape;
      final inType   = _interpreter!.getInputTensor(0).type;
      debugPrint('[CNN] Input: $inShape type=$inType  Output: $outShape');

      _runInferenceInternal(Float32List(_kImgSize * _kImgSize * 3));
      debugPrint('[CNN] Modelo listo. Warm-up OK.');
      _lastError = null;
    } catch (e) {
      _interpreter?.close();
      _interpreter = null;
      _lastError = e.toString();
      debugPrint('[CNN] Error al cargar modelo: $e');
      rethrow;
    } finally {
      _loading = false;
    }
  }

  Float32List runInference(Float32List inputTensor) {
    if (_interpreter == null) {
      throw StateError('Modelo no inicializado. Llama initialize() primero.');
    }
    return _runInferenceInternal(inputTensor);
  }

  Float32List _runInferenceInternal(Float32List flat) {
    // Escribir input en el buffer nativo (Float32List→Float32List = memcpy directo)
    _interpreter!.getInputTensor(0).data.buffer.asFloat32List().setAll(0, flat);
    _interpreter!.invoke();
    return Float32List.fromList(
      _interpreter!.getOutputTensor(0).data.buffer.asFloat32List(),
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    debugPrint('[CNN] Intérprete liberado.');
  }
}
