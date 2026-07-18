import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Fondo de espera de [DiagnosisPage] antes de tomar una foto.
class DiagnosisIdlePlaceholder extends StatelessWidget {
  const DiagnosisIdlePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.diagnosisCameraGradientStart, AppColors.black],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 52,
              color: AppColors.onPrimary.withValues(alpha: 0.18),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Toca el botón para fotografiar\ntu cultivo',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onPrimary.withValues(alpha: 0.28),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
