import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Encabezado del acordeón "Información adicional (opcional)" de
/// [AddParcelPage].
class ParcelAccordionHeader extends StatelessWidget {
  const ParcelAccordionHeader({
    super.key,
    required this.expanded,
    required this.onTap,
  });

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Información adicional (opcional)',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.parcelsTextPrimary,
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_outlined
                  : Icons.keyboard_arrow_down_outlined,
              color: AppColors.parcelsTextPrimary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
