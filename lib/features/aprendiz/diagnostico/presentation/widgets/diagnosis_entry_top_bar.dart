import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Barra superior de [DiagnosisEntryAprendizPage].
class DiagnosisEntryTopBar extends StatelessWidget {
  final VoidCallback onInfoTap;
  const DiagnosisEntryTopBar({super.key, required this.onInfoTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.aPrimaryContainer,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.menu, color: AppColors.aOnPrimary), onPressed: () {}),
          Expanded(
            child: Text(
              'Diagnóstico',
              textAlign: TextAlign.center,
              style: AppTypography.agendaTitle.copyWith(color: AppColors.aOnPrimary, fontSize: 19),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.aOnPrimary),
            onPressed: onInfoTap,
          ),
        ],
      ),
    );
  }
}
