import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/estado_resumen_entity.dart';

class EstadoResumenTile extends StatelessWidget {
  final EstadoResumenEntity estado;
  final VoidCallback? onTap;

  const EstadoResumenTile({super.key, required this.estado, this.onTap});

  String _formatHa(double ha) {
    final formatted = ha.toStringAsFixed(ha.truncateToDouble() == ha ? 0 : 1);
    return '$formatted ha';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lgXl),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.xxlPlus,
          AppSpacing.none,
          AppSpacing.xxlPlus,
          AppSpacing.lg,
        ),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    estado.estado,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${estado.campanias} campañas',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${estado.campaniaDominante} · ${estado.cultivoDominante}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _pill('${estado.productores} productores'),
                const SizedBox(width: AppSpacing.sm),
                _pill(_formatHa(estado.superficieHa)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxsPlus,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
