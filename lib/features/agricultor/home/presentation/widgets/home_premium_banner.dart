import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../subscription/presentation/pages/subscription_page.dart';

/// Banner de promoción a la suscripción Pro, mostrado en HomePage.
class HomePremiumBanner extends StatelessWidget {
  const HomePremiumBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, SubscriptionPage.route()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: Border.all(
            color: AppColors.primaryContainer.withValues(alpha: 0.8),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.forestGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: AppColors.onPrimary, size: 14),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Desbloquea diagnósticos ilimitados y alertas avanzadas. '),
                    TextSpan(
                      text: 'Mejorar a Pro →',
                      style: AppTypography.etiquetaSm.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
