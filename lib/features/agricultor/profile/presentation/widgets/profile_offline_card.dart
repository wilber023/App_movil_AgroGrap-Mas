import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../offline/presentation/cubit/offline_cubit.dart';
import '../../../offline/presentation/pages/offline_mode_page.dart';

/// Acceso rápido a "Diagnóstico sin Conexión" en [ProfilePage] — solo
/// navegación, sin toggle.
class ProfileOfflineCard extends StatelessWidget {
  const ProfileOfflineCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfflineCubit, OfflineState>(
      builder: (context, state) {
        final loaded = state is OfflineLoaded ? state : null;
        final isEnabled = loaded?.status.isOfflineModeEnabled ?? false;
        final downloaded = loaded?.status.downloadedCount ?? 0;
        final total = loaded?.status.totalAvailableCount ?? 0;

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppColors.forestGreen.withValues(alpha: 0.15)
                  : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              size: 20,
              color: isEnabled
                  ? AppColors.forestGreen
                  : AppColors.onSurfaceVariant,
            ),
          ),
          title: Text(
            'Diagnóstico sin Conexión',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          ),
          subtitle: Text(
            loaded != null
                ? (downloaded > 0
                    ? '$downloaded/$total guías · ${isEnabled ? "Modo activo" : "Modo inactivo"}'
                    : 'Gestiona recursos para uso sin internet')
                : 'Gestiona recursos para uso sin internet',
            style: AppTypography.etiquetaSm
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: AppColors.outlineVariant, size: 20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OfflineModePage()),
          ),
        );
      },
    );
  }
}
