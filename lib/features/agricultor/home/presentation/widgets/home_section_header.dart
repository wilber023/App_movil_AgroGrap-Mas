import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Encabezado de sección reutilizado por los bloques de HomePage: título +
/// enlace de acción opcional ("Ver agenda", "Ver todos", ...).
class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback onTap;
  const HomeSectionHeader({super.key, required this.title, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action!,
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.forestGreen, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}
