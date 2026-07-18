import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../offline_knowledge/presentation/cubit/offline_package_manager_cubit.dart';
import '../cubit/offline_cubit.dart';

// =============================================================================
// HELPERS
// =============================================================================

String _cropEmoji(String cropName) => switch (cropName) {
      'Tomate' => '🍅',
      'Maíz' => '🌽',
      'Papa' => '🥔',
      'Frijol' => '🫘',
      'Calabaza' => '🍈',
      _ => '🌿',
    };

// =============================================================================
// PAGE
// =============================================================================

class OfflineModePage extends StatefulWidget {
  const OfflineModePage({super.key});

  @override
  State<OfflineModePage> createState() => _OfflineModePageState();
}

class _OfflineModePageState extends State<OfflineModePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OfflineCubit>().loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OfflinePackageManagerCubit>()..loadStatuses(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Diagnóstico sin Conexión',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AppColors.onPrimary)),
              Text('Descarga paquetes de diagnóstico para usar sin internet',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white70)),
            ],
          ),
        ),
        body: BlocBuilder<OfflineCubit, OfflineState>(
          builder: (context, state) => switch (state) {
            OfflineInitial() || OfflineLoading() => const _LoadingBody(),
            OfflineError(:final message) => _ErrorBody(
                message: message,
                onRetry: () => context.read<OfflineCubit>().loadStatus(),
              ),
            OfflineLoaded() => _LoadedBody(state: state),
          },
        ),
      ),
    );
  }
}

// =============================================================================
// LOADING
// =============================================================================

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
              color: AppColors.forestGreen, strokeWidth: 2.5),
          const SizedBox(height: AppSpacing.xxlPlus),
          Text('Cargando recursos...',
              style: AppTypography.etiquetaSm
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// =============================================================================
// BODY PRINCIPAL
// =============================================================================

class _LoadedBody extends StatelessWidget {
  final OfflineLoaded state;
  const _LoadedBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.forestGreen,
      onRefresh: () async =>
          context.read<OfflinePackageManagerCubit>().loadStatuses(),
      child: BlocBuilder<OfflinePackageManagerCubit, OfflinePackageManagerState>(
        builder: (context, pkgState) {
          final crops = OfflinePackageManagerCubit.supportedCrops
              .map((c) => pkgState.statuses[c])
              .whereType<CropPackageStatus>()
              .toList();
          final downloaded = crops
              .where((c) => c.phase == PackageDownloadPhase.downloaded)
              .toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.huge, AppSpacing.xxlPlus, AppSpacing.giant),
            children: [
              _OfflineToggleCard(state: state),
              const SizedBox(height: AppSpacing.xxhuge),

              // ── Cultivos ──────────────────────────────────────────────────
              _SectionLabel(
                title: 'CULTIVOS DISPONIBLES',
                subtitle: 'Toca un cultivo para descargar su paquete de '
                    'diagnóstico offline',
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (pkgState.loading && crops.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xhuge),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.forestGreen,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else
                ...crops.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: _CropPackageCard(status: c),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              // ── Descargado ────────────────────────────────────────────────
              _SectionLabel(
                title: 'DESCARGADO',
                subtitle: downloaded.isEmpty
                    ? 'Sin paquetes locales aún'
                    : '${downloaded.length} paquete${downloaded.length > 1 ? "s" : ""} '
                        'disponible${downloaded.length > 1 ? "s" : ""} sin conexión',
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (downloaded.isEmpty)
                const _EmptyDownloadedState()
              else
                ...downloaded.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _DownloadedPackageTile(status: c),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// TOGGLE — modo sin conexión (sin cambios: sigue leyendo el OfflineCubit
// legacy, es una preferencia independiente del estado real de los paquetes)
// =============================================================================

class _OfflineToggleCard extends StatelessWidget {
  final OfflineLoaded state;
  const _OfflineToggleCard({required this.state});

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

// =============================================================================
// SECTION LABEL
// =============================================================================

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xxsPlus),
        Text(subtitle,
            style: AppTypography.etiquetaSm
                .copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

// =============================================================================
// CROP PACKAGE CARD — un paquete completo por cultivo (offline_knowledge)
// =============================================================================

class _CropPackageCard extends StatelessWidget {
  final CropPackageStatus status;
  const _CropPackageCard({required this.status});

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
                  Text(_cropEmoji(status.cultivo),
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

// =============================================================================
// DOWNLOADED PACKAGE TILE
// =============================================================================

class _DownloadedPackageTile extends StatelessWidget {
  final CropPackageStatus status;
  const _DownloadedPackageTile({required this.status});

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
                    Text(_cropEmoji(status.cultivo),
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

// =============================================================================
// EMPTY STATE — sin descargas
// =============================================================================

class _EmptyDownloadedState extends StatelessWidget {
  const _EmptyDownloadedState();

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

// =============================================================================
// ERROR
// =============================================================================

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

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
