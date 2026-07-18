import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'diagnosis_entry_card_shadow.dart';

/// Banner "INSPECCIÓN PENDIENTE · SEMANA N" + separador "O REALIZA UN
/// DIAGNÓSTICO LIBRE" de [DiagnosisEntryAprendizPage], mostrado solo cuando
/// hay una inspección semanal pendiente.
class DiagnosisPendingInspectionBanner extends StatelessWidget {
  const DiagnosisPendingInspectionBanner({super.key, required this.nextWeek});

  final int nextWeek;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.aWarningBg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.aWarningBorder),
            boxShadow: kAprendizDiagnosisCardShadow,
          ),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.event_note_rounded, color: AppColors.aOrange, size: 20),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INSPECCIÓN PENDIENTE · SEMANA $nextWeek',
                      style: AppTypography.etiquetaSm.copyWith(
                        color: AppColors.aWarningText,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tu plan indica que es momento de revisar tu cultivo.',
                      style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.huge),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.aOutlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                'O REALIZA UN DIAGNÓSTICO LIBRE',
                style: AppTypography.etiquetaSm.copyWith(
                  fontSize: 10,
                  color: AppColors.aOnSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.aOutlineVariant)),
          ],
        ),
        const SizedBox(height: AppSpacing.huge),
      ],
    );
  }
}
