import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

// -- Status Pill --

class StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.textColor,
    this.icon,
  });

  factory StatusPill.healthy() => const StatusPill(
        label: 'Saludable',
        background: AppColors.statusHealthyBg,
        textColor: AppColors.statusHealthyText,
        icon: Icons.check_circle_outline_rounded,
      );

  factory StatusPill.atRisk() => const StatusPill(
        label: 'En Riesgo',
        background: AppColors.statusAtRiskBg,
        textColor: AppColors.statusAtRiskText,
        icon: Icons.warning_amber_rounded,
      );

  factory StatusPill.offline() => const StatusPill(
        label: 'Sin conexion',
        background: AppColors.statusOfflineBg,
        textColor: AppColors.statusOfflineText,
        icon: Icons.cloud_off_outlined,
      );

  factory StatusPill.severity(String level) {
    switch (level.toLowerCase()) {
      case 'alta':
        return const StatusPill(
          label: 'ALTA SEVERIDAD',
          background: AppColors.error,
          textColor: Colors.white,
          icon: Icons.error_outline_rounded,
        );
      case 'media':
        return const StatusPill(
          label: 'MEDIA SEVERIDAD',
          background: AppColors.warmAmber,
          textColor: Colors.white,
          icon: Icons.warning_amber_rounded,
        );
      default:
        return StatusPill.healthy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppTypography.statusPill.copyWith(color: textColor)),
        ],
      ),
    );
  }
}

// -- Info Card --

class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? borderColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor = AppColors.forestGreen,
    this.borderColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor ?? AppColors.cardBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.etiquetaSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// -- Progress Bar --

class AppProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color? backgroundColor;
  final double height;

  const AppProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.forestGreen,
    this.backgroundColor,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        color: color,
        backgroundColor: backgroundColor ?? color.withValues(alpha: 0.15),
      ),
    );
  }
}

// -- Offline Banner --

class OfflineBanner extends StatelessWidget {
  final String message;

  const OfflineBanner({
    super.key,
    this.message = 'Sin conexion - datos en cola',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.offlineGreyDark,
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.etiquetaSm.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Section Header --

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.tituloMd.copyWith(color: AppColors.onSurface),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// -- Metric Card --

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.forestGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.headlineMd.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
