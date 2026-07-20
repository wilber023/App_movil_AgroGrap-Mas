import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Barra inferior de la pantalla de Resultado: agendar seguimiento del
/// diagnostico. El diagnostico en si ya se persiste automaticamente al
/// analizarlo, asi que no hace falta un boton de guardado aparte — el CTA
/// principal (aOrange, mismo tono que el resto de la marca aprendiz) queda
/// como unica accion, a todo el ancho, para que sea inequivoca.
class DiagnosisResultBottomBar extends StatelessWidget {
  final VoidCallback onScheduleFollowUp;
  final bool isSchedulingFollowUp;

  const DiagnosisResultBottomBar({
    super.key,
    required this.onScheduleFollowUp,
    required this.isSchedulingFollowUp,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isSchedulingFollowUp ? null : onScheduleFollowUp,
        icon: isSchedulingFollowUp
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.aOnPrimary),
              )
            : const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.aOnPrimary),
        label: Text(
          isSchedulingFollowUp ? 'Agendando...' : 'Agendar seguimiento',
          style: AppTypography.agendaTitle.copyWith(fontSize: 16, color: AppColors.aOnPrimary),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.aOrange,
          disabledBackgroundColor: AppColors.aOrange.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
          elevation: 0,
        ),
      ),
    );
  }
}
