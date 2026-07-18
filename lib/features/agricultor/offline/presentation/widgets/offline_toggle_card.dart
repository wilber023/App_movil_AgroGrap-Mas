import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../cubit/offline_cubit.dart';

/// Tarjeta de toggle "Modo sin conexión" en [OfflineModePage]. Sigue
/// leyendo el [OfflineCubit] legado (sin cambios): es una preferencia
/// independiente del estado real de los paquetes descargados.
class OfflineToggleCard extends StatelessWidget {
  final OfflineLoaded state;
  const OfflineToggleCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final enabled = state.status.isOfflineModeEnabled;
    final downloaded = state.status.downloadedCount;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                colors: [
                  AppColors.forestGreen.withValues(alpha: 0.15),
                  AppColors.forestGreen.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enabled ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
        border: Border.all(
          color: enabled
              ? AppColors.forestGreen.withValues(alpha: 0.45)
              : AppColors.outlineVariant,
          width: enabled ? 1.2 : 0.8,
        ),
        boxShadow: [
          if (!enabled)
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.xxl),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.forestGreen.withValues(alpha: 0.18)
                    : AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                enabled ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                color:
                    enabled ? AppColors.forestGreen : AppColors.offlineGrey,
                size: 21,
              ),
            ),
            const SizedBox(width: AppSpacing.xxl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo sin conexión',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    enabled
                        ? 'Activo · $downloaded guía${downloaded != 1 ? "s" : ""} disponibles'
                        : 'Activa para diagnóstico sin internet',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: enabled
                          ? AppColors.forestGreen
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: (val) =>
                  context.read<OfflineCubit>().toggleOfflineMode(enabled: val),
              thumbColor: WidgetStateProperty.all(AppColors.onPrimary),
              activeTrackColor: AppColors.forestGreen,
              inactiveTrackColor: AppColors.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}
