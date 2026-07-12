import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

const int _kImgSize = 224;

// Normalización ImageNet idéntica al entrenamiento Python (albumentations)
const double _meanR = 0.485, _meanG = 0.456, _meanB = 0.406;
const double _stdR  = 0.229, _stdG  = 0.224, _stdB  = 0.225;

/// Ejecutar con compute() para no bloquear el hilo de UI.
/// Retorna tensor NCHW [3×224×224] como Float32List (sin dimensión batch).
Float32List preprocessImageIsolate(String imagePath) {
  final bytes = File(imagePath).readAsBytesSync();
  img.Image decoded = img.decodeImage(bytes) ??
      img.Image(width: _kImgSize, height: _kImgSize);

  // Forzar RGB uint8 — elimina canal alpha y formatos distintos
  // Así pixel.r/g/b siempre devuelven enteros 0-255
  if (decoded.format != img.Format.uint8 || decoded.numChannels != 3) {
    decoded = decoded.convert(format: img.Format.uint8, numChannels: 3);
  }

  // Bicúbico: coincide con PIL BICUBIC que usa torchvision transforms.Resize por defecto.
  // Bilinear producía píxeles distintos suficientes para cambiar el ranking de predicciones.
  final resized = img.copyResize(
    decoded,
    width: _kImgSize,
    height: _kImgSize,
    interpolation: img.Interpolation.cubic,
  );

  // NCHW layout: [1, 3, 224, 224] — todos los píxeles de R primero, luego G, luego B.
  // El modelo TFLite mantiene el orden NCHW de PyTorch (sin transpose en la conversión).
  final pixelCount = _kImgSize * _kImgSize;
  final tensor = Float32List(pixelCount * 3);

  for (int h = 0; h < _kImgSize; h++) {
    for (int w = 0; w < _kImgSize; w++) {
      final pixel = resized.getPixel(w, h);
      final flat = h * _kImgSize + w;
      tensor[flat]                = (pixel.r.toDouble() / 255.0 - _meanR) / _stdR;
      tensor[pixelCount + flat]   = (pixel.g.toDouble() / 255.0 - _meanG) / _stdG;
      tensor[pixelCount * 2 + flat] = (pixel.b.toDouble() / 255.0 - _meanB) / _stdB;
    }
  }


  return tensor;
}
