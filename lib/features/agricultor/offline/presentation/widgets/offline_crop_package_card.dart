import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../offline_knowledge/presentation/cubit/offline_package_manager_cubit.dart';
import 'offline_helpers.dart';

/// Tarjeta de un paquete de diagnóstico offline por cultivo en
/// [OfflineModePage] (offline_knowledge).
class OfflineCropPackageCard extends StatelessWidget {
  final CropPackageStatus status;
  const OfflineCropPackageCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final downloaded = status.phase == PackageDownloadPhase.downloaded;
    final downloading = status.phase == PackageDownloadPhase.downloading;
    final hasError = status.phase == PackageDownloadPhase.error;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: downloaded
            ? AppColors.forestGreen.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
        border: Border.all(
          color: downloaded
              ? AppColors.forestGreen.withValues(alpha: 0.45)
              : AppColors.offlineCardBorder,
          width: downloaded ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: downloaded ? 0.01 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.xxlPlus, AppSpacing.xxlPlus, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offlineCropEmoji(status.cultivo),
                      style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.cultivo,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: -0.4,
                              color: downloaded
                                  ? AppColors.forestGreen
                                  : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxsPlus),
                          Text(
                            'Paquete de diagnóstico offline',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.onSurfaceVariant,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: downloaded
                        ? Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.forestGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: AppColors.onPrimary, size: 16),
                          )
                        : (downloading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.forestGreen,
                                ),
                              )
                            : const SizedBox.shrink()),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),
              Divider(
                height: 1,
                thickness: 0.6,
                color: downloaded
                    ? AppColors.forestGreen.withValues(alpha: 0.2)
                    : AppColors.offlineCardBorder,
              ),
              const SizedBox(height: AppSpacing.xl),

              if (hasError) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 15, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        status.errorMessage ??
                            'No se pudo descargar el paquete.',
                        style: AppTypography.etiquetaSm
                            .copyWith(color: AppColors.error, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── Acción ────────────────────────────────────────────────
              _buildActionRow(context, downloaded: downloaded, downloading: downloading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context, {
    required bool downloaded,
    required bool downloading,
  }) {
    if (downloaded) {
      return Row(
        children: [
          const Icon(Icons.offline_pin_rounded,
              color: AppColors.forestGreen, size: 15),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Disponible sin conexión',
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.forestGreen,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(
          downloading ? 'Descargando…' : 'No descargado',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: downloading
              ? null
              : () => context
                  .read<OfflinePackageManagerCubit>()
                  .download(status.cultivo),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.forestGreen,
            disabledBackgroundColor: AppColors.surfaceContainerHigh,
            foregroundColor: AppColors.onPrimary,
            disabledForegroundColor: AppColors.onSurfaceVariant,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.mdLg),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lgXl),
            ),
          ),
          icon: Icon(
            downloading
                ? Icons.hourglass_top_rounded
                : Icons.download_rounded,
            size: 15,
          ),
          label: Text(
            downloading ? 'Descargando' : 'Descargar',
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
