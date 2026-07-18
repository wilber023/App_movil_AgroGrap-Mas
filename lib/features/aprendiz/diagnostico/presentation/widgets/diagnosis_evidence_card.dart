import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'diagnosis_result_card.dart';

/// Tarjeta "¿Cómo llegamos a este resultado?": indicios detectados por la
/// IA (`llmResponse.sintomas`), ya una lista — no se muestran parrafos.
class DiagnosisEvidenceCard extends StatelessWidget {
  final List<String> evidence;

  const DiagnosisEvidenceCard({super.key, required this.evidence});

  @override
  Widget build(BuildContext context) {
    return DiagnosisResultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.travel_explore, size: 16, color: AppColors.infoBlue),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '¿Cómo llegamos a este resultado?',
                  style: AppTypography.etiquetaBold.copyWith(color: AppColors.aOnSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...evidence.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 14, color: AppColors.infoBlue),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
