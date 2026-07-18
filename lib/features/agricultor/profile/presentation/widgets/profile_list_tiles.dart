import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Título de sección en mayúsculas de [ProfilePage] (ej. "MI CUENTA").
class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md, bottom: AppSpacing.xs),
      child: Text(
        title,
        style: AppTypography.labelMd.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Fila de lista genérica de [ProfilePage] (título, icono, subtítulo
/// opcional, trailing personalizable).
class ProfileListTile extends StatelessWidget {
  const ProfileListTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.textColor = AppColors.onSurface,
    this.iconColor = AppColors.onSurfaceVariant,
    this.trailingWidget,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final Color textColor;
  final Color iconColor;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.none),
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        title,
        style: AppTypography.bodyMd.copyWith(color: textColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.etiquetaSm
                  .copyWith(color: AppColors.onSurfaceVariant),
            )
          : null,
      trailing: trailingWidget ??
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.outlineVariant, size: 20),
      onTap: onTap ?? () {},
    );
  }
}

/// Fila de enlace externo de [ProfilePage] (Legal y privacidad).
class ProfileExternalLinkTile extends StatelessWidget {
  const ProfileExternalLinkTile(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.none),
      title: Text(
        title,
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
      ),
      trailing: const Icon(Icons.open_in_new_rounded,
          color: AppColors.outlineVariant, size: 20),
      onTap: () {},
    );
  }
}
