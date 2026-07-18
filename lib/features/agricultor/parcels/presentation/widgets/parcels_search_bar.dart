import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Barra de búsqueda de [ParcelsPage] (aún no filtra la lista — solo UI).
class ParcelsSearchBar extends StatelessWidget {
  const ParcelsSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.onPrimary,
          borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
          border: Border.all(
            color: AppColors.parcelsBorderLight.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar parcela...',
            hintStyle: AppTypography.etiquetaSm.copyWith(
              color: AppColors.parcelsBorderLight,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search_outlined,
              color: AppColors.parcelsTextSecondary,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxlPlus,
              vertical: AppSpacing.xxl,
            ),
          ),
        ),
      ),
    );
  }
}
