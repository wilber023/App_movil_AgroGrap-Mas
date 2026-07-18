import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Estado vacío de la sección "DESCARGADO" en [OfflineModePage].
class OfflineEmptyDownloadedState extends StatelessWidget {
  const OfflineEmptyDownloadedState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xhuge, vertical: AppSpacing.xxhuge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.6),
            width: 0.6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_download_outlined,
                size: 28, color: AppColors.offlineGrey),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Sin paquetes descargados',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Selecciona un cultivo arriba y descarga\nsu paquete para diagnóstico sin internet.',
            textAlign: TextAlign.center,
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
