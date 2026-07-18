import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../utils/subscription_plans.dart';

/// Tarjeta tipo "boleto" con el resumen del plan (icono, nombre, precio y
/// beneficios principales) en [CheckoutPage], para que el checkout se
/// sienta como una compra premium y no como un formulario bancario.
class CheckoutPlanTicket extends StatelessWidget {
  const CheckoutPlanTicket({super.key, required this.plan});

  final SubscriptionPlanInfo plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.huge,
              vertical: AppSpacing.xxxl,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.forestGreen],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xxl),
                topRight: Radius.circular(AppRadius.xxl),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.lgXl),
                  ),
                  child: Icon(plan.icon, color: AppColors.onPrimary, size: 22),
                ),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(
                  child: Text(
                    plan.title,
                    style: AppTypography.tituloMd.copyWith(color: AppColors.onPrimary),
                  ),
                ),
                Text(
                  plan.priceLabel,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.huge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incluye',
                  style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...plan.features.take(3).map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.lg),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
