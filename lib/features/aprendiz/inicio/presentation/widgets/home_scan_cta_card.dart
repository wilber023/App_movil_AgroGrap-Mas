import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Tarjeta de llamada a la accion "Escanear cultivo": lleva directo al
/// modulo de Diagnostico (`DiagnosisEntryAprendizPage`).
class HomeScanCtaCard extends StatelessWidget {
  final VoidCallback onScan;

  const HomeScanCtaCard({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.aPrimaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.aOnPrimary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: AppColors.aOnPrimary, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Escanear cultivo',
                            style: AppTypography.agendaSubtitle.copyWith(color: AppColors.aOnPrimary),
                          ),
                          Text(
                            'Diagnóstico IA en segundos',
                            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxlPlus),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onScan,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.aPrimary),
                    label: Text(
                      'Tomar fotografía',
                      style: AppTypography.labelMd.copyWith(color: AppColors.aPrimary, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.aOnPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mdLg)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
