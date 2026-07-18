import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Chip genérico de una sola etiqueta (ej. nombre del cultivo) usado en
/// [ParcelsPage].
class ParcelChip extends StatelessWidget {
  const ParcelChip({super.key, required this.label, required this.bg, required this.textColor});

  final String label;
  final Color bg;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxsPlus),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

/// Chip de estado (Alerta/Seguimiento/Saludable/Sin diagnóstico) con icono.
class ParcelStatusChip extends StatelessWidget {
  const ParcelStatusChip({
    super.key,
    required this.label,
    required this.bg,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final Color bg;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxsPlus),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de conteo de diagnósticos locales guardados para una parcela.
class ParcelDiagCountChip extends StatelessWidget {
  const ParcelDiagCountChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd, vertical: AppSpacing.xxsPlus),
      decoration: BoxDecoration(
        color: AppColors.parcelsChipBlueBg,
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.analytics_outlined, size: 10, color: AppColors.parcelsChipBlueText),
          const SizedBox(width: AppSpacing.xxsPlus),
          Text(
            '$count ${count == 1 ? 'diagnóstico' : 'diagnósticos'}',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.parcelsChipBlueText,
            ),
          ),
        ],
      ),
    );
  }
}
