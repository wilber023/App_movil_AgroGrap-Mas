import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Sección "ZONA DE PELIGRO" de [ProfilePage]: cerrar sesión y eliminar
/// cuenta.
class ProfileDangerZone extends StatelessWidget {
  const ProfileDangerZone({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.xs),
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(
              'Cerrar sesión',
              style: AppTypography.labelMd.copyWith(color: AppColors.error),
            ),
            onTap: onLogout,
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.xs),
            leading:
                const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            title: Text(
              'Eliminar mi cuenta',
              style: AppTypography.labelMd.copyWith(color: AppColors.error),
            ),
            subtitle: Text(
              'Esta acción es permanente e irreversible',
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.error),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
