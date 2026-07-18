import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Barra inferior de la pantalla de Resultado: guardar diagnostico
/// (confirmacion — el diagnostico ya se persiste al analizarlo) y agendar
/// seguimiento.
class DiagnosisResultBottomBar extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onScheduleFollowUp;
  final bool isSchedulingFollowUp;

  const DiagnosisResultBottomBar({
    super.key,
    required this.onSave,
    required this.onScheduleFollowUp,
    required this.isSchedulingFollowUp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.bookmark_border, size: 18, color: AppColors.aSecondary),
            label: Text(
              'Guardar diagnóstico',
              style: AppTypography.labelMd.copyWith(color: AppColors.aSecondary, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.aSecondary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isSchedulingFollowUp ? null : onScheduleFollowUp,
            icon: isSchedulingFollowUp
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.aOnPrimary),
                  )
                : const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.aOnPrimary),
            label: Text(
              'Agendar seguimiento',
              style: AppTypography.labelMd.copyWith(color: AppColors.aOnPrimary, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.aSecondary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
