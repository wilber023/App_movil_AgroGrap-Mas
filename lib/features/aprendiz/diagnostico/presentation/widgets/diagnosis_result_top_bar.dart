import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Barra superior de [DiagnosisResultAprendizPage].
class DiagnosisResultTopBar extends StatelessWidget {
  const DiagnosisResultTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.aPrimaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.aOnPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Resultado de tu análisis',
              textAlign: TextAlign.center,
              style: AppTypography.agendaTitle.copyWith(fontSize: 17, color: AppColors.aOnPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.xgiantPlus),
        ],
      ),
    );
  }
}
