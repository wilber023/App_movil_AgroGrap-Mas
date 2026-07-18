import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../models/diagnosis_result_view_data.dart';

/// Pill de severidad del diagnostico, coloreada desde el sistema de temas.
/// Reutilizable en cualquier tarjeta que necesite mostrar severidad.
class DiagnosisSeverityBadge extends StatelessWidget {
  final SeverityLevel severity;

  const DiagnosisSeverityBadge({super.key, required this.severity});

  (Color bg, Color fg, IconData icon, String label) get _style => switch (severity) {
        SeverityLevel.low => (AppColors.aSecondaryContainer, AppColors.aOnSecondaryContainer, Icons.check_circle_outline, 'Leve'),
        SeverityLevel.moderate => (AppColors.aWarningBg, AppColors.aWarningText, Icons.warning_amber_rounded, 'Moderada'),
        SeverityLevel.high => (AppColors.aDiseaseCardBg, AppColors.aDiseaseCardText, Icons.error_outline, 'Alta'),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xsPlus),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTypography.etiquetaSm.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
