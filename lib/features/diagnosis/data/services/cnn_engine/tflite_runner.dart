import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

const int _kImgSize = 380;

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
    // ── Diagnóstico de entrada ────────────────────────────────────────────────
    double inAbsSum = 0;
    for (int i = 0; i < 100; i++) { inAbsSum += flat[i].abs(); }
    debugPrint('[CNN] Sum abs primeros 100 valores flat: ${inAbsSum.toStringAsFixed(4)}');

    // ── Escribir input en el buffer nativo del tensor ─────────────────────────
    // getInputTensor(0).data devuelve Uint8List sobre memoria nativa FFI.
    // Reinterpretado como Float32List → setAll es un memcpy directo sin
    // conversión de tipos (Float32List→Float32List, no double 64-bit).
    final inputNative = _interpreter!.getInputTensor(0).data.buffer.asFloat32List();
    inputNative.setAll(0, flat);

    // Verificar que el write llegó al buffer nativo (si devuelve copia, la
    // suma sería 0 incluso después de setAll — eso indica que necesitamos FFI)
    double verifySum = 0;
    for (int i = 0; i < 100; i++) { verifySum += inputNative[i].abs(); }
    debugPrint('[CNN] Verify native input (0=copia, >0=vista nativa): ${verifySum.toStringAsFixed(4)}');

    // ── Ejecutar inferencia ────────────────────────────────────────────────────
    _interpreter!.invoke();

    // ── Leer output del buffer nativo ─────────────────────────────────────────
    final outputNative = _interpreter!.getOutputTensor(0).data.buffer.asFloat32List();
    final result = Float32List.fromList(outputNative);

    // ── Diagnóstico de salida ─────────────────────────────────────────────────
    final outSum = result.fold<double>(0.0, (a, b) => a + b);
    final outMin = result.reduce(math.min);
    final outMax = result.reduce(math.max);
    final mean     = outSum / result.length;
    final variance = result.fold<double>(0.0, (a, b) => a + (b - mean) * (b - mean)) / result.length;
    debugPrint(
      '[CNN] output: sum=${outSum.toStringAsFixed(4)}'
      ' min=${outMin.toStringAsFixed(4)}'
      ' max=${outMax.toStringAsFixed(4)}'
      ' var=${variance.toStringAsFixed(6)}'
      '\n      → sum≈1.0 && var>0  ⇒ softmax horneado (postprocessing lo detecta)'
      '\n      → sum≈0 || var≈0    ⇒ input inválido',
    );

    return result;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    debugPrint('[CNN] Intérprete liberado.');
  }
}
