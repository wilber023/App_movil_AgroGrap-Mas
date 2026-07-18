import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Nota discreta al final de la pantalla de Diagnostico, recordando el
/// caracter educativo de los resultados.
class DiagnosisEducationalFootnote extends StatelessWidget {
  const DiagnosisEducationalFootnote({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 14, color: AppColors.aOnSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Los resultados tienen fines educativos y no sustituyen la evaluación de un especialista.',
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
