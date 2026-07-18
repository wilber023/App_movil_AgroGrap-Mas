import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Pill "Cosecha estimada: fecha" mostrada bajo el campo de fecha de siembra
/// una vez seleccionada.
class CultivoHarvestEstimateChip extends StatelessWidget {
  final String formattedDate;
  const CultivoHarvestEstimateChip({super.key, required this.formattedDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.aSecondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_available_outlined, size: 16, color: AppColors.aSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Cosecha estimada: $formattedDate',
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.aSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
