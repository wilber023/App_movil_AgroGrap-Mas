import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Etiqueta de sección (título + subtítulo) usada en [OfflineModePage] para
/// separar "CULTIVOS DISPONIBLES" y "DESCARGADO".
class OfflineSectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  const OfflineSectionLabel({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xxsPlus),
        Text(subtitle,
            style: AppTypography.etiquetaSm
                .copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}
