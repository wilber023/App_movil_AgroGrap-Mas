import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Estado vacío del historial de diagnósticos, compartido por
/// [DiagnosisHistorySheet] y [DiagnosisHistoryFullPage]. El botón "Ir a
/// cámara" solo aparece cuando se provee [onGoToCamera] (la vista sheet no
/// lo mostraba en el original).
class DiagnosisHistoryEmptyState extends StatelessWidget {
  const DiagnosisHistoryEmptyState({super.key, this.onGoToCamera});

  final VoidCallback? onGoToCamera;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppColors.parcelsChipGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.parcelsAddGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            Text(
              'Aún no hay diagnósticos',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.parcelsTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Toma tu primera foto para analizar el estado de tus cultivos.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.parcelsTextSecondary),
              textAlign: TextAlign.center,
            ),
            if (onGoToCamera != null) ...[
              const SizedBox(height: AppSpacing.xxlPlus),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onGoToCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmAmber,
                    foregroundColor: AppColors.onWarmAmber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lgXl),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Ir a cámara →',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
