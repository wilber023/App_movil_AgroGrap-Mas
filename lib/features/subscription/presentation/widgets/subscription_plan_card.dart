import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/shared_components.dart';
import '../pages/checkout_page.dart';
import '../utils/subscription_plans.dart';

/// Tarjeta de un plan de suscripción en [SubscriptionPage] (Free, Mensual,
/// Anual).
class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({super.key, required this.plan, required this.isActive});

  final SubscriptionPlanInfo plan;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.id != 'free';
    final highlight = plan.recommended && !isActive;
    final borderColor = highlight
        ? AppColors.warmAmber
        : (isPremium ? AppColors.primary : AppColors.cardBorder);
    final bgColor = isPremium
        ? AppColors.primaryContainer.withValues(alpha: 0.1)
        : AppColors.cardSurface;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: borderColor, width: highlight ? 2.5 : (isPremium ? 2 : 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: isPremium ? 0.08 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (highlight)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.warmAmber,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xlPlus),
                  topRight: Radius.circular(AppRadius.xlPlus),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: AppColors.onPrimary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'MÁS POPULAR',
                    style: AppTypography.statusPill.copyWith(color: AppColors.onPrimary),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xhuge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: (isPremium ? AppColors.primary : AppColors.forestGreen)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.mdLg),
                      ),
                      child: Icon(
                        plan.icon,
                        size: 18,
                        color: isPremium ? AppColors.primary : AppColors.forestGreen,
                      ),
                    ),
                    Text(
                      plan.title,
                      style: AppTypography.tituloMd.copyWith(
                        color: isPremium ? AppColors.primary : AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (plan.badge != null)
                      StatusPill(
                        label: plan.badge!,
                        background: AppColors.warmAmber.withValues(alpha: 0.18),
                        textColor: AppColors.tertiary,
                      ),
                    if (isActive)
                      StatusPill(
                        label: 'Plan Actual',
                        background: AppColors.statusHealthyBg,
                        textColor: AppColors.statusHealthyText,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  plan.priceLabel,
                  style: AppTypography.tituloLg.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: AppSpacing.xhuge),
                ...plan.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: isPremium ? AppColors.primary : AppColors.forestGreen,
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: Text(
                            feature,
                            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!isActive && isPremium)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => CheckoutPage.push(context, plan: plan.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: highlight ? AppColors.warmAmber : AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
                      ),
                      child: Text(
                        highlight ? 'Elegir el más popular' : 'Mejorar ahora',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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
