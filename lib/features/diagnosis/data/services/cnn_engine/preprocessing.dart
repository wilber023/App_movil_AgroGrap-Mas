import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

const int _kImgSize = 380;

// Normalización ImageNet idéntica al entrenamiento Python (albumentations)
const double _meanR = 0.485, _meanG = 0.456, _meanB = 0.406;
const double _stdR  = 0.229, _stdG  = 0.224, _stdB  = 0.225;

/// Ejecutar con compute() para no bloquear el hilo de UI.
/// Retorna tensor NHWC [380×380×3] como Float32List (sin dimensión batch).
Float32List preprocessImageIsolate(String imagePath) {
  final bytes = File(imagePath).readAsBytesSync();
  img.Image decoded = img.decodeImage(bytes) ??
      img.Image(width: _kImgSize, height: _kImgSize);

  // Forzar RGB uint8 — elimina canal alpha y formatos distintos
  // Así pixel.r/g/b siempre devuelven enteros 0-255
  if (decoded.format != img.Format.uint8 || decoded.numChannels != 3) {
    decoded = decoded.convert(format: img.Format.uint8, numChannels: 3);
  }

  final resized = img.copyResize(
    decoded,
    width: _kImgSize,
    height: _kImgSize,
    interpolation: img.Interpolation.linear,
  );

  final tensor = Float32List(_kImgSize * _kImgSize * 3);
  int idx = 0;
  for (int h = 0; h < _kImgSize; h++) {
    for (int w = 0; w < _kImgSize; w++) {
      final pixel = resized.getPixel(w, h);
      // pixel.r/g/b son int 0-255 en Format.uint8 → /255.0 da [0.0, 1.0]
      tensor[idx++] = (pixel.r.toDouble() / 255.0 - _meanR) / _stdR;
      tensor[idx++] = (pixel.g.toDouble() / 255.0 - _meanG) / _stdG;
      tensor[idx++] = (pixel.b.toDouble() / 255.0 - _meanB) / _stdB;
    }
  }

  // Debug: pixel central para verificar rango esperado (~[-2.1, +2.7])
  final ci = ((_kImgSize ~/ 2) * _kImgSize + _kImgSize ~/ 2) * 3;
  debugPrint(
    '[Preprocessing] pixel_central norm:'
    ' R=${tensor[ci].toStringAsFixed(3)}'
    ' G=${tensor[ci + 1].toStringAsFixed(3)}'
    ' B=${tensor[ci + 2].toStringAsFixed(3)}',
  );

  return tensor;
}
