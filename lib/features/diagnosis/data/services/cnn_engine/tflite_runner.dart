import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

const int _kImgSize = 380;
const int _kNumClasses = 50;

/// Singleton que gestiona el ciclo de vida del intérprete TFLite.
/// Carga el modelo UNA sola vez, hace warm-up y mantiene el intérprete vivo.
class GlobalModelManager {
  GlobalModelManager._();
  static final GlobalModelManager instance = GlobalModelManager._();

  Interpreter? _interpreter;
  bool _loading = false;
  String? _lastError;

  bool get isReady => _interpreter != null;
  String? get lastError => _lastError;

  /// Inicializa el modelo desde assets. Idempotente.
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
      debugPrint('[CNN] Input: $inShape  Output: $outShape');

      // Warm-up con entrada de ceros
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

  /// Retorna logits crudos [kNumClasses].
  /// DEBE llamarse desde el mismo hilo donde se inicializó el Interpreter.
  Float32List runInference(Float32List inputTensor) {
    if (_interpreter == null) {
      throw StateError(
        'Modelo no inicializado. Llama initialize() primero.',
      );
    }
    return _runInferenceInternal(inputTensor);
  }

  Float32List _runInferenceInternal(Float32List flat) {
    // Construir tensor de entrada [1][380][380][3] sin depender de reshape
    final input = List.generate(
      1,
      (_) => List.generate(
        _kImgSize,
        (h) => List.generate(
          _kImgSize,
          (w) => List.generate(
            3,
            (c) => flat[(h * _kImgSize + w) * 3 + c],
          ),
        ),
      ),
    );

    // Tensor de salida [1][50]
    final output = [List<double>.filled(_kNumClasses, 0.0)];
    _interpreter!.run(input, output);

    return Float32List.fromList(output[0]);
  }

  /// Libera el intérprete. Llamar al desmontar la feature de diagnóstico.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    debugPrint('[CNN] Intérprete liberado.');
  }
}
