import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// SnackBar consistente para toda la feature: flotante, con icono y
/// esquinas redondeadas, en vez del SnackBar plano por defecto.
void showSubscriptionSnack(BuildContext context, String message, {bool isError = true}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : AppColors.forestGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
        margin: const EdgeInsets.all(AppSpacing.xxlPlus),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: AppColors.onPrimary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(message, style: AppTypography.labelMd.copyWith(color: AppColors.onPrimary)),
            ),
          ],
        ),
      ),
    );
}
