import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Overlay de éxito mostrado tras guardar una parcela nueva, con acceso
/// directo a diagnóstico o a la lista de parcelas.
class ParcelSuccessOverlay extends StatelessWidget {
  final String cropName;
  final VoidCallback onDiagnosis;
  final VoidCallback onViewParcels;

  const ParcelSuccessOverlay({
    super.key,
    required this.cropName,
    required this.onDiagnosis,
    required this.onViewParcels,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.forestGreen,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.giant),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.onPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.forestGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.huge),
                Text(
                  '¡Parcela registrada!',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Tu cultivo de $cropName ha sido guardado. Puedes realizar tu primer diagnóstico cuando lo necesites.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onPrimary.withValues(alpha: 0.75),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.giant),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onDiagnosis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warmAmber,
                      foregroundColor: AppColors.onWarmAmber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lgXl),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Ir a diagnóstico →',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onViewParcels,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onPrimary,
                      side: const BorderSide(color: AppColors.onPrimary, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lgXl),
                      ),
                    ),
                    child: Text(
                      'Ver mis parcelas',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
