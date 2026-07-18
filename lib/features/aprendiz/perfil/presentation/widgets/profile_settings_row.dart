import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Fila de opcion dentro de una [ProfileSettingsCard]: icono, etiqueta y
/// chevron (o texto/icono final personalizado).
class ProfileSettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final IconData? trailingIcon;
  final Color? iconColor;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const ProfileSettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.trailingIcon,
    this.iconColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(AppRadius.lgXl) : Radius.zero,
        bottom: isLast ? const Radius.circular(AppRadius.lgXl) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxlPlus,
          vertical: AppSpacing.xxl,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.aOnSurfaceVariant, size: 22),
            const SizedBox(width: AppSpacing.xxl),
            Expanded(
              child: Text(
                label,
                style: AppTypography.agendaBody.copyWith(fontSize: 15, color: iconColor ?? AppColors.aOnSurface),
              ),
            ),
            if (trailing != null) ...[
              Text(trailing!, style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant)),
              const SizedBox(width: AppSpacing.md),
            ],
            Icon(trailingIcon ?? Icons.chevron_right, color: AppColors.aOnSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Variante de [ProfileSettingsRow] con un `Switch` en vez de chevron
/// (usada por "Modo sin conexión").
class ProfileSettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ProfileSettingsSwitchRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxlPlus,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.aOnSurfaceVariant, size: 22),
          const SizedBox(width: AppSpacing.xxl),
          Expanded(
            child: Text(
              label,
              style: AppTypography.agendaBody.copyWith(fontSize: 15, color: AppColors.aOnSurface),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.aSecondary,
            activeTrackColor: AppColors.aSecondaryContainer,
          ),
        ],
      ),
    );
  }
}

/// Divisor entre filas de una [ProfileSettingsCard].
class ProfileRowDivider extends StatelessWidget {
  const ProfileRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, indent: AppSpacing.xxgiant, color: AppColors.aOutlineVariant);
  }
}
