import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'diagnosis_result_card.dart';

/// Tarjeta "Riesgos": que puede ocurrir si no se atiende el problema
/// (`llmResponse.avisos`, ya una lista). Si no hay avisos, no se renderiza.
class DiagnosisRiskCard extends StatelessWidget {
  final List<String> risks;

  const DiagnosisRiskCard({super.key, required this.risks});

  @override
  Widget build(BuildContext context) {
    if (risks.isEmpty) return const SizedBox.shrink();

    return DiagnosisResultCard(
      color: AppColors.aWarningBg,
      borderColor: AppColors.aWarningBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: AppColors.aOrange),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Riesgos', style: AppTypography.etiquetaBold.copyWith(color: AppColors.aWarningText)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            risks.join(' '),
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aWarningText, height: 1.3),
          ),
        ],
      ),
    );
  }
}
