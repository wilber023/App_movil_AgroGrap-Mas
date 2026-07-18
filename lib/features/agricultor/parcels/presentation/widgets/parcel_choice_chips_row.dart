import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Fila de chips seleccionables usada tanto para selección única (tipo de
/// terreno) como múltiple (condición del suelo, malezas) en [AddParcelPage].
/// El widget solo renderiza; la semántica de selección (reemplazar vs.
/// alternar) la decide quien construye [isSelected]/[onItemTap].
class ParcelChoiceChipsRow extends StatelessWidget {
  const ParcelChoiceChipsRow({
    super.key,
    required this.items,
    required this.isSelected,
    required this.onItemTap,
  });

  final List<String> items;
  final bool Function(int index) isSelected;
  final ValueChanged<int> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(items.length, (i) {
        final selected = isSelected(i);
        return GestureDetector(
          onTap: () => onItemTap(i),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.parcelsChipGreenBg
                  : AppColors.parcelsMutedBg,
              borderRadius: BorderRadius.circular(AppRadius.mdLg),
              border: selected
                  ? Border.all(color: AppColors.forestGreen, width: 0.5)
                  : null,
            ),
            child: Text(
              items[i],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: selected
                    ? AppColors.forestGreen
                    : AppColors.parcelsUnselectedText,
              ),
            ),
          ),
        );
      }),
    );
  }
}
