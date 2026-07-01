import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/offline_document_entity.dart';
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

  void _showDownloadToast(BuildContext ctx, String message) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2128),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.burntOrange.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: AppColors.burntOrange, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Función no disponible aún',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(message,
                        style: const TextStyle(
                            color: Color(0xFFADB5BD),
                            fontSize: 11.5,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Diagnóstico sin Conexión',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.white)),
            Text('Descarga guías para usar sin internet',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70)),
          ],
        ),
      ),
      body: BlocConsumer<OfflineCubit, OfflineState>(
        listener: (context, state) {
          if (state is OfflineLoaded && state.toastError != null) {
            _showDownloadToast(context, state.toastError!);
            context.read<OfflineCubit>().clearToastError();
          }
        },
        builder: (context, state) => switch (state) {
          OfflineInitial() || OfflineLoading() => const _LoadingBody(),
          OfflineError(:final message) => _ErrorBody(
              message: message,
              onRetry: () => context.read<OfflineCubit>().loadStatus(),
            ),
          OfflineLoaded() => _LoadedBody(state: state),
        },
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
          const SizedBox(height: 16),
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
    final grouped = _groupByCrop(state.documents);
    final downloaded = state.documents.where((d) => d.isDownloaded).toList();

    return RefreshIndicator(
      color: AppColors.forestGreen,
      onRefresh: () async => context.read<OfflineCubit>().loadStatus(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _OfflineToggleCard(state: state),
          const SizedBox(height: 28),

          // ── Cultivos ──────────────────────────────────────────────────────
          _SectionLabel(
            title: 'CULTIVOS DISPONIBLES',
            subtitle:
                'Toca un cultivo para descargar sus guías fitosanitarias',
          ),
          const SizedBox(height: 14),
          ...grouped.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CropCard(
                cropName: e.key,
                documents: e.value,
                downloadingDocId: state.downloadingDocId,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Descargado ────────────────────────────────────────────────────
          _SectionLabel(
            title: 'DESCARGADO',
            subtitle: downloaded.isEmpty
                ? 'Sin guías locales aún'
                : '${downloaded.length} guía${downloaded.length > 1 ? "s" : ""} disponible${downloaded.length > 1 ? "s" : ""} sin conexión',
          ),
          const SizedBox(height: 14),
          if (downloaded.isEmpty)
            const _EmptyDownloadedState()
          else
            ...downloaded.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DownloadedDocTile(doc: doc),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, List<OfflineDocumentEntity>> _groupByCrop(
      List<OfflineDocumentEntity> docs) {
    final map = <String, List<OfflineDocumentEntity>>{};
    for (final doc in docs) {
      map.putIfAbsent(doc.cropName, () => []).add(doc);
    }
    return map;
  }
}

// =============================================================================
// TOGGLE — modo sin conexión
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
              ? AppColors.forestGreen.withValues(alpha: 0.45)
              : AppColors.outlineVariant,
          width: enabled ? 1.2 : 0.8,
        ),
        boxShadow: [
          if (!enabled)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
            const SizedBox(width: 14),
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
                  const SizedBox(height: 2),
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
              thumbColor: WidgetStateProperty.all(Colors.white),
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
        const SizedBox(height: 3),
        Text(subtitle,
            style: AppTypography.etiquetaSm
                .copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

// =============================================================================
// CROP CARD — emoji + modern design
// =============================================================================

class _CropCard extends StatelessWidget {
  final String cropName;
  final List<OfflineDocumentEntity> documents;
  final String? downloadingDocId;

  const _CropCard({
    required this.cropName,
    required this.documents,
    required this.downloadingDocId,
  });

  bool get _isThisCropDownloading =>
      downloadingDocId != null &&
      documents.any((d) => d.id == downloadingDocId);
  bool get _isAnyDownloading => downloadingDocId != null;
  int get _downloadedCount => documents.where((d) => d.isDownloaded).length;
  bool get _allDownloaded => _downloadedCount == documents.length;
  bool get _noneDownloaded => _downloadedCount == 0;

  String get _totalSizeLabel {
    final bytes = documents.fold(0, (sum, d) => sum + d.sizeBytes);
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final dc = _downloadedCount;
    final total = documents.length;
    final allDone = _allDownloaded;
    final isThisDownloading = _isThisCropDownloading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: allDone
            ? AppColors.forestGreen.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allDone
              ? AppColors.forestGreen.withValues(alpha: 0.45)
              : const Color(0xFFE5EAF0),
          width: allDone ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: allDone ? 0.01 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: AppColors.forestGreen.withValues(alpha: 0.07),
            highlightColor: AppColors.forestGreen.withValues(alpha: 0.03),
            onTap: (!isThisDownloading && !_isAnyDownloading && !allDone)
                ? () {
                    final ids = documents
                        .where((d) => !d.isDownloaded)
                        .map((d) => d.id)
                        .toList();
                    context.read<OfflineCubit>().downloadCropDocs(ids);
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji
                      Text(_cropEmoji(cropName),
                          style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 12),
                      // Nombre + enfermedades
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cropName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  letterSpacing: -0.4,
                                  color: allDone
                                      ? AppColors.forestGreen
                                      : AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                documents.map((d) => d.diseaseName).join(' · '),
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
                      const SizedBox(width: 8),
                      // Indicador de progreso / completado
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: allDone
                            ? Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppColors.forestGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16),
                              )
                            : _ProgressDots(
                                downloaded: dc, total: total),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    thickness: 0.6,
                    color: allDone
                        ? AppColors.forestGreen.withValues(alpha: 0.2)
                        : const Color(0xFFE5EAF0),
                  ),
                  const SizedBox(height: 12),

                  // ── Acción ────────────────────────────────────────────────
                  if (isThisDownloading)
                    _DownloadingRow(
                      documents: documents,
                      downloadingDocId: downloadingDocId!,
                    )
                  else
                    _ActionRow(
                      downloadedCount: dc,
                      total: total,
                      allDone: allDone,
                      noneDownloaded: _noneDownloaded,
                      totalSizeLabel: _totalSizeLabel,
                      isAnyDownloading: _isAnyDownloading,
                      onDownload: () {
                        final ids = documents
                            .where((d) => !d.isDownloaded)
                            .map((d) => d.id)
                            .toList();
                        context.read<OfflineCubit>().downloadCropDocs(ids);
                      },
                      onDelete: () => _confirmDelete(context),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Eliminar $cropName'),
        content: Text(
          '¿Eliminar las $_downloadedCount guía${_downloadedCount > 1 ? "s" : ""} '
          'descargadas de $cropName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        final ids = documents
            .where((d) => d.isDownloaded)
            .map((d) => d.id)
            .toList();
        context.read<OfflineCubit>().deleteCropDocs(ids);
      }
    });
  }
}

// =============================================================================
// DOWNLOADING ROW
// =============================================================================

class _DownloadingRow extends StatelessWidget {
  final List<OfflineDocumentEntity> documents;
  final String downloadingDocId;

  const _DownloadingRow({
    required this.documents,
    required this.downloadingDocId,
  });

  @override
  Widget build(BuildContext context) {
    final doc = documents.firstWhere(
      (d) => d.id == downloadingDocId,
      orElse: () => documents.first,
    );
    final done = documents.where((d) => d.isDownloaded).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Descargando ${doc.diseaseName}...',
                style: const TextStyle(
                  color: AppColors.forestGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${done + 1}/${documents.length}',
              style: const TextStyle(
                color: AppColors.forestGreen,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: const LinearProgressIndicator(
            minHeight: 4,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ACTION ROW
// =============================================================================

class _ActionRow extends StatelessWidget {
  final int downloadedCount;
  final int total;
  final bool allDone;
  final bool noneDownloaded;
  final String totalSizeLabel;
  final bool isAnyDownloading;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _ActionRow({
    required this.downloadedCount,
    required this.total,
    required this.allDone,
    required this.noneDownloaded,
    required this.totalSizeLabel,
    required this.isAnyDownloading,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (allDone) {
      return Row(
        children: [
          const Icon(Icons.offline_pin_rounded,
              color: AppColors.forestGreen, size: 15),
          const SizedBox(width: 6),
          Text(
            'Disponible sin conexión',
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.forestGreen,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
            ),
            child: const Text('Eliminar',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(
          noneDownloaded
              ? '~$totalSizeLabel'
              : '$downloadedCount/$total descargadas',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: isAnyDownloading ? null : onDownload,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.forestGreen,
            disabledBackgroundColor: AppColors.surfaceContainerHigh,
            foregroundColor: Colors.white,
            disabledForegroundColor: AppColors.onSurfaceVariant,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(
            noneDownloaded
                ? Icons.download_rounded
                : Icons.download_for_offline_rounded,
            size: 15,
          ),
          label: Text(
            noneDownloaded ? 'Descargar' : 'Continuar',
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PROGRESS DOTS
// =============================================================================

class _ProgressDots extends StatelessWidget {
  final int downloaded;
  final int total;
  const _ProgressDots({required this.downloaded, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isDone = i < downloaded;
        return Padding(
          padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  isDone ? AppColors.forestGreen : AppColors.outlineVariant,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// DOWNLOADED DOC TILE
// =============================================================================

class _DownloadedDocTile extends StatelessWidget {
  final OfflineDocumentEntity doc;
  const _DownloadedDocTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.forestGreen.withValues(alpha: 0.28), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_cropEmoji(doc.cropName),
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        doc.diseaseName,
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
                const SizedBox(height: 2),
                Text(
                  '${doc.cropName} · ${doc.source} · ${doc.sizeLabel}',
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                context.read<OfflineCubit>().deleteDocument(doc.id),
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.error),
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 34, minHeight: 34),
            tooltip: 'Eliminar',
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 14),
          Text(
            'Sin guías descargadas',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selecciona un cultivo arriba y descarga\nsus guías para diagnóstico sin internet.',
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
        padding: const EdgeInsets.all(32),
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
            const SizedBox(height: 18),
            Text(
              'Error al cargar recursos',
              style: AppTypography.labelMd.copyWith(
                  color: AppColors.onSurface, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.etiquetaSm
                  .copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
