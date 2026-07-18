import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../offline_knowledge/presentation/cubit/offline_package_manager_cubit.dart';
import '../cubit/offline_cubit.dart';
import 'offline_crop_package_card.dart';
import 'offline_downloaded_package_tile.dart';
import 'offline_empty_downloaded_state.dart';
import 'offline_section_label.dart';
import 'offline_toggle_card.dart';

/// Cuerpo principal de [OfflineModePage] una vez cargado: toggle de modo
/// sin conexión, cultivos disponibles y paquetes ya descargados.
class OfflineLoadedBody extends StatelessWidget {
  final OfflineLoaded state;
  const OfflineLoadedBody({super.key, required this.state});

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
              OfflineToggleCard(state: state),
              const SizedBox(height: AppSpacing.xxhuge),

              // ── Cultivos ──────────────────────────────────────────────────
              const OfflineSectionLabel(
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
                    child: OfflineCropPackageCard(status: c),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              // ── Descargado ────────────────────────────────────────────────
              OfflineSectionLabel(
                title: 'DESCARGADO',
                subtitle: downloaded.isEmpty
                    ? 'Sin paquetes locales aún'
                    : '${downloaded.length} paquete${downloaded.length > 1 ? "s" : ""} '
                        'disponible${downloaded.length > 1 ? "s" : ""} sin conexión',
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (downloaded.isEmpty)
                const OfflineEmptyDownloadedState()
              else
                ...downloaded.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: OfflineDownloadedPackageTile(status: c),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
