import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Estado de procesamiento de [CheckoutPage] (esperando PayPal / verificando
/// el pago).
class CheckoutProcessingView extends StatelessWidget {
  const CheckoutProcessingView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('processing'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: AppSpacing.huge),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            ),
            const SizedBox(height: AppSpacing.huge),
            Text(
              title,
              style: AppTypography.tituloMd.copyWith(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
