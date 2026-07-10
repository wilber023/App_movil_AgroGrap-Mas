import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.aWarningBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.aWarningText),
              const SizedBox(width: 6),
              Text(
                'Avisos importantes',
                style: AppTypography.etiquetaBold.copyWith(fontSize: 13, color: AppColors.aPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...notices.map(
            (notice) => Padding(
              padding: const EdgeInsets.only(top: 2),
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
