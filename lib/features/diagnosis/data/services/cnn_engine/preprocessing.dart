import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

const int _kImgSize = 380;

// ImageNet normalization constants (mismo que el entrenamiento Python)
const double _meanR = 0.485, _meanG = 0.456, _meanB = 0.406;
const double _stdR  = 0.229, _stdG  = 0.224, _stdB  = 0.225;

/// Ejecutar con compute() para no bloquear el hilo de UI.
/// Retorna tensor NHWC [1 × 380 × 380 × 3] como Float32List.
Float32List preprocessImageIsolate(String imagePath) {
  final bytes = File(imagePath).readAsBytesSync();
  img.Image decoded;
  decoded = img.decodeImage(bytes) ?? img.Image(width: _kImgSize, height: _kImgSize);

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
      // pixel.r/g/b son enteros 0-255 para imágenes uint8
      tensor[idx++] = (pixel.r / 255.0 - _meanR) / _stdR;
      tensor[idx++] = (pixel.g / 255.0 - _meanG) / _stdG;
      tensor[idx++] = (pixel.b / 255.0 - _meanB) / _stdB;
    }
  }
  return tensor;
}
