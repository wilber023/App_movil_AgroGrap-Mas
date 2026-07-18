import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../models/diagnosis_result_view_data.dart';

/// Anillo circular de confianza del reconocimiento, con el porcentaje al
/// centro y una etiqueta de nivel (Alta/Media/Baja) coloreada por tema.
/// Reutilizable en cualquier pantalla que necesite mostrar una confianza.
class DiagnosisConfidenceRing extends StatelessWidget {
  final double confidence;
  final ConfidenceLevel level;
  final double size;

  const DiagnosisConfidenceRing({
    super.key,
    required this.confidence,
    required this.level,
    this.size = 64,
  });

  (Color, String) get _levelStyle => switch (level) {
        ConfidenceLevel.high => (AppColors.aSecondary, 'Alta'),
        ConfidenceLevel.medium => (AppColors.aOrange, 'Media'),
        ConfidenceLevel.low => (AppColors.error, 'Baja'),
      };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _levelStyle;
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: confidence.clamp(0, 1),
                  strokeWidth: 5,
                  backgroundColor: AppColors.aSurfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: AppTypography.etiquetaBold.copyWith(color: AppColors.aOnSurface),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.etiquetaSm.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
