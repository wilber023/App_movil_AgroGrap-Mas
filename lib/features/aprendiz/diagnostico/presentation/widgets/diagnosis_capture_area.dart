import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Area de captura de foto de la pantalla de Diagnostico. Sin foto: borde
/// punteado + texto guia. Con foto: vista previa + boton para quitarla.
/// Widget puro — no conoce camara/galeria, solo expone [onTap]/[onRemove].
class DiagnosisCaptureArea extends StatelessWidget {
  final String? imagePath;
  final bool isEnabled;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const DiagnosisCaptureArea({
    super.key,
    required this.imagePath,
    required this.isEnabled,
    required this.onTap,
    required this.onRemove,
  });

  bool get _hasPhoto => imagePath != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 190),
        decoration: BoxDecoration(
          color: _hasPhoto ? AppColors.aSurfaceContainerLowest : AppColors.aMint,
          borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        ),
        child: _hasPhoto
            ? Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: Image.file(
                      File(imagePath!),
                      height: 210,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: GestureDetector(
                      onTap: isEnabled ? onRemove : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.aOnSurface.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.xsPlus),
                        child: const Icon(Icons.close, color: AppColors.aOnPrimary, size: 16),
                      ),
                    ),
                  ),
                ],
              )
            : CustomPaint(
                painter: _DashedBorderPainter(color: AppColors.aSecondaryContainer),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xhuge),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.aSecondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: AppColors.aSecondary, size: 30),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'Toca para tomar una foto',
                        style: AppTypography.agendaTitle.copyWith(fontSize: 18, color: AppColors.aOnSurface),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Hoja, fruto o tallo afectado',
                        style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Pinta un borde punteado sobre un rectangulo redondeado, sin depender de
/// paquetes externos.
class _DashedBorderPainter extends CustomPainter {
  final Color color;

  static const _radius = 16.0;
  static const _strokeWidth = 2.0;
  static const _dashWidth = 6.0;
  static const _dashSpace = 5.0;

  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _strokeWidth / 2,
        _strokeWidth / 2,
        size.width - _strokeWidth,
        size.height - _strokeWidth,
      ),
      const Radius.circular(_radius),
    );
    final borderPath = Path()..addRRect(rRect);
    final dashedPath = Path();

    for (final metric in borderPath.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        dashedPath.addPath(metric.extractPath(distance, next.clamp(0, metric.length)), Offset.zero);
        distance = next + _dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
