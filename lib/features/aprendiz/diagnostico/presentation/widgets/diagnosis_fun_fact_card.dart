import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'diagnosis_result_card.dart';

/// Tarjeta educativa "Aprende algo nuevo" (`llmResponse.explicacion`). Si el
/// diagnostico no trae explicacion, no se renderiza nada — la estructura
/// queda lista para cuando el backend la incluya.
class DiagnosisFunFactCard extends StatelessWidget {
  final String? funFact;

  const DiagnosisFunFactCard({super.key, required this.funFact});

  @override
  Widget build(BuildContext context) {
    final fact = funFact;
    if (fact == null || fact.isEmpty) return const SizedBox.shrink();

    return DiagnosisResultCard(
      color: AppColors.aTertiaryFixed,
      borderColor: AppColors.aOnTertiaryFixedVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 16, color: AppColors.aOnTertiaryFixedVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Aprende algo nuevo',
                  style: AppTypography.etiquetaBold.copyWith(color: AppColors.aOnTertiaryFixedVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '¿Sabías que...?',
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnTertiaryFixedVariant, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            fact,
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnTertiaryFixedVariant, height: 1.3),
          ),
        ],
      ),
    );
  }
}
