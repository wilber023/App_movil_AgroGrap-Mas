import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../offline_knowledge/presentation/cubit/offline_package_manager_cubit.dart';
import 'offline_helpers.dart';

/// Fila compacta de un paquete ya descargado, en la sección "DESCARGADO"
/// de [OfflineModePage].
class OfflineDownloadedPackageTile extends StatelessWidget {
  final CropPackageStatus status;
  const OfflineDownloadedPackageTile({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(
            color: AppColors.forestGreen.withValues(alpha: 0.28), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.forestGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.forestGreen, size: 18),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(offlineCropEmoji(status.cultivo),
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: AppSpacing.xsPlus),
                    Expanded(
                      child: Text(
                        status.cultivo,
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Paquete de diagnóstico offline disponible',
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
