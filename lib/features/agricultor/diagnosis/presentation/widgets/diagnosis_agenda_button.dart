import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Botón "Agregar tratamiento a la agenda" (o su estado ya-agregado) de
/// [DiagnosisResultPage]. La lógica de negocio permanece en la página;
/// este widget solo refleja [isAddedToAgenda] e invoca [onAddPressed].
class DiagnosisAgendaButton extends StatelessWidget {
  const DiagnosisAgendaButton({
    super.key,
    required this.isAddedToAgenda,
    required this.onAddPressed,
  });

  final bool isAddedToAgenda;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: SizedBox(
        width: double.infinity,
        child: isAddedToAgenda
            ? OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: Text(
                  'Tratamiento en agenda',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forestGreen,
                  disabledForegroundColor: AppColors.forestGreen,
                  side: const BorderSide(
                    color: AppColors.forestGreen,
                    width: 0.8,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xlPlus),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.mdLg),
                  ),
                ),
              )
            : ElevatedButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.event_note_outlined, size: 16),
                label: Text(
                  'Agregar tratamiento a la agenda',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xlPlus),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.mdLg),
                  ),
                  elevation: 0,
                ),
              ),
      ),
    );
  }
}
