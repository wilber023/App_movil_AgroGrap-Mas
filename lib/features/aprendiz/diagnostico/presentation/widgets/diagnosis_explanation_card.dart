import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'diagnosis_result_card.dart';

/// Tarjeta "¿Qué está pasando?": explicacion del diagnostico en lenguaje
/// sencillo (ya simplificado por el LLM en `llmResponse.diagnostico`).
class DiagnosisExplanationCard extends StatelessWidget {
  final String explanation;

  const DiagnosisExplanationCard({super.key, required this.explanation});

  @override
  Widget build(BuildContext context) {
    return DiagnosisResultCard(
      color: AppColors.aMint,
      borderColor: AppColors.aSecondaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.aSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '¿Qué está pasando?',
                  style: AppTypography.etiquetaBold.copyWith(color: AppColors.aOnSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }
}
