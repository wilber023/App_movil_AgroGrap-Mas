import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Estado de carga inicial de [OfflineModePage].
class OfflineLoadingBody extends StatelessWidget {
  const OfflineLoadingBody({super.key});

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
