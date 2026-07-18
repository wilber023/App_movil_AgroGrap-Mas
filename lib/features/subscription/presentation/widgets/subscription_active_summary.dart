import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription_entity.dart';
import '../utils/subscription_plans.dart';

/// Resumen del plan activo (nombre + próximo cobro) en [SubscriptionPage].
class SubscriptionActiveSummary extends StatelessWidget {
  const SubscriptionActiveSummary({super.key, required this.subscription});

  final SubscriptionEntity subscription;

  @override
  Widget build(BuildContext context) {
    final nextBilling = subscription.nextBillingTime;
    final nextBillingLabel = nextBilling != null
        ? '${nextBilling.day.toString().padLeft(2, '0')}/${nextBilling.month.toString().padLeft(2, '0')}/${nextBilling.year}'
        : '—';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      decoration: BoxDecoration(
        color: AppColors.statusHealthyBg,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(color: AppColors.statusHealthyText.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: AppColors.statusHealthyText),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan ${SubscriptionPlans.byId(subscription.planType).title} activo',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.statusHealthyText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Próximo cobro: $nextBillingLabel',
                  style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
