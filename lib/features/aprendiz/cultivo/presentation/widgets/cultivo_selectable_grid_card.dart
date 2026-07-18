import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Tarjeta seleccionable generica usada por las grillas del formulario de
/// registro (cultivo a sembrar, lugar de practica). Un unico widget evita
/// duplicar el estilo de seleccion entre ambas grillas.
class CultivoSelectableGridCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CultivoSelectableGridCard({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.aSecondaryContainer : AppColors.aSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: Border.all(
            color: isSelected ? AppColors.aSecondary : AppColors.aOutlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.etiquetaSm.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.aSecondary : AppColors.aOnSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
