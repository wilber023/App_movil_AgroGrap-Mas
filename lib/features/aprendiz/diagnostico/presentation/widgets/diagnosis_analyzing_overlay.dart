import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'diagnosis_entry_card_shadow.dart';

/// Overlay ligero mostrado mientras se analiza la foto en
/// [DiagnosisEntryAprendizPage], para reforzar que la app está trabajando
/// (además del estado del botón).
class DiagnosisAnalyzingOverlay extends StatelessWidget {
  const DiagnosisAnalyzingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.xl,
      left: AppSpacing.xxlPlus,
      right: AppSpacing.xxlPlus,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.aPrimaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.lgXl),
            boxShadow: kAprendizDiagnosisCardShadow,
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(color: AppColors.aOnPrimary, strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  'Estamos revisando tu foto con inteligencia artificial...',
                  style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnPrimary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
