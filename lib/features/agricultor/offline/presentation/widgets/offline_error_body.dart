import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Estado de error de [OfflineModePage] (ej. no se pudo cargar el estado
/// de los paquetes), con reintento.
class OfflineErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const OfflineErrorBody({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 34, color: AppColors.offlineGrey),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              'Error al cargar recursos',
              style: AppTypography.labelMd.copyWith(
                  color: AppColors.onSurface, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.etiquetaSm
                  .copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.xhuge),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xhuge, vertical: AppSpacing.xl),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
