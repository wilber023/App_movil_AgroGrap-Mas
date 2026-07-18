import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../login/auth/domain/entities/user_entity.dart';

/// Encabezado de usuario de [ProfilePage] con datos reales del AuthBloc.
class ProfileUserHeader extends StatelessWidget {
  const ProfileUserHeader({super.key, required this.user, required this.onUpgradeTap});

  final UserEntity user;
  final VoidCallback onUpgradeTap;

  static String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return 'AG';
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(user.fullName.isNotEmpty
        ? user.fullName
        : user.username.isNotEmpty
            ? user.username
            : 'AG');

    final displayName =
        user.fullName.isNotEmpty ? user.fullName : user.username;
    final displaySub = user.email ?? user.phone ?? 'Agricultor';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      decoration: BoxDecoration(
        color: AppColors.statusHealthyBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.forestGreen,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xxlPlus),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTypography.tituloMd.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  displaySub,
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lgXl),
                    border: Border.all(
                        color: AppColors.outlineVariant, width: 0.5),
                  ),
                  child: Text(
                    'PLAN FREE',
                    style: AppTypography.etiquetaSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onUpgradeTap,
            child: Text(
              'Mejorar a Pro →',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.burntOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
