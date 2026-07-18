import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/home_notice_entity.dart';

/// Tarjeta de avisos importantes: solo se renderiza cuando hay al menos un
/// aviso real activo — sin avisos no ocupa espacio, para no agregar bulto
/// visual que no esta en el diseño de referencia cuando no hay nada urgente
/// que reportar.
class HomeNoticesCard extends StatelessWidget {
  final List<HomeNoticeEntity> notices;

  const HomeNoticesCard({super.key, required this.notices});

  @override
  Widget build(BuildContext context) {
    if (notices.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.aWarningBg,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(color: AppColors.aWarningBorder),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.aWarningText),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Avisos importantes',
                style: AppTypography.etiquetaBold.copyWith(fontSize: 13, color: AppColors.aPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...notices.map(
            (notice) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                '• ${notice.message}',
                style: AppTypography.etiquetaSm.copyWith(color: AppColors.aWarningText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
