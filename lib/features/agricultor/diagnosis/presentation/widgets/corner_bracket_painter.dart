import 'package:flutter/material.dart';

/// Pinta las 4 esquinas del marco de encuadre en [DiagnosisPage] (sin
/// rellenar el rectángulo completo, solo las "L" de cada esquina).
class CornerBracketPainter extends CustomPainter {
  final Color color;
  final double armLength;
  final double strokeWidth;

  const CornerBracketPainter({
    required this.color,
    required this.armLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final a = armLength;

    canvas.drawLine(Offset(0, a), Offset.zero, paint);
    canvas.drawLine(Offset.zero, Offset(a, 0), paint);

    canvas.drawLine(Offset(w - a, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, a), paint);

    canvas.drawLine(Offset(0, h - a), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(a, h), paint);

    canvas.drawLine(Offset(w, h - a), Offset(w, h), paint);
    canvas.drawLine(Offset(w - a, h), Offset(w, h), paint);
  }

  @override
  bool shouldRepaint(covariant CornerBracketPainter old) => color != old.color;
}
