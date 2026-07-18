import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'diagnosis_result_card.dart';

/// Tarjeta "Próximo paso recomendado": acción sugerida + boton para
/// navegar a la seccion correspondiente (tratamiento).
class DiagnosisNextStepCard extends StatelessWidget {
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  const DiagnosisNextStepCard({
    super.key,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return DiagnosisResultCard(
      color: AppColors.infoBlue.withValues(alpha: 0.10),
      borderColor: AppColors.infoBlue.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.arrow_circle_right_outlined, size: 16, color: AppColors.infoBlue),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Próximo paso', style: AppTypography.etiquetaBold.copyWith(color: AppColors.infoBlue)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant, height: 1.3),
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.infoBlue),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: Text(
                actionLabel,
                style: AppTypography.etiquetaSm.copyWith(color: AppColors.infoBlue, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
