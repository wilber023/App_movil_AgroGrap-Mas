import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'diagnosis_result_card.dart';

/// Nota final recordando el caracter educativo del diagnostico.
class DiagnosisImportantNoteCard extends StatelessWidget {
  const DiagnosisImportantNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DiagnosisResultCard(
      color: AppColors.aWarningBg,
      borderColor: AppColors.aWarningBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.aWarningText),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.etiquetaSm.copyWith(color: AppColors.aWarningText, height: 1.4),
                children: [
                  TextSpan(text: 'Importante: ', style: AppTypography.etiquetaBold.copyWith(color: AppColors.aWarningText)),
                  const TextSpan(
                    text: 'este diagnóstico es una orientación educativa y no sustituye la evaluación '
                        'de un especialista. Observa tu cultivo y toma decisiones informadas.',
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
