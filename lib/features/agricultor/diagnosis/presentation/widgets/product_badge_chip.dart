import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Badge compacto (ej. "MEJOR OPCIÓN", "ECOLÓGICO") usado en las tarjetas
/// de producto recomendado dentro de [DiagnosisResultPage].
class ProductBadgeChip extends StatelessWidget {
  const ProductBadgeChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd, vertical: AppSpacing.xxsPlus),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: color.withValues(alpha: 0.30), width: 0.5),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.4,
      ),
    ),
  );
}
