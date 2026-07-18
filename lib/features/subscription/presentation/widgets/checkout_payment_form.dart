import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../utils/subscription_plans.dart';
import '../widgets/card_number_field.dart';
import 'checkout_plan_ticket.dart';

/// Formulario de pago de [CheckoutPage]: resumen del plan, campo de
/// tarjeta (solo visual, el cobro real va por PayPal) y botón de pago.
class CheckoutPaymentForm extends StatelessWidget {
  const CheckoutPaymentForm({super.key, required this.plan, required this.onPay});

  final SubscriptionPlanInfo plan;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const ValueKey('form'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.huge,
          vertical: AppSpacing.xhuge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckoutPlanTicket(plan: plan),
            const SizedBox(height: AppSpacing.giant),
            Row(
              children: [
                const Icon(Icons.credit_card_rounded, size: 20, color: AppColors.onSurface),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Método de pago',
                  style: AppTypography.tituloMd.copyWith(color: AppColors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            CardNumberField(onCardTypeChanged: (_) {}),
            const SizedBox(height: AppSpacing.xhuge),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.infoBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.lgXl),
                border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.infoBlue),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      'Serás redirigido a PayPal para confirmar el pago de forma segura.',
                      style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xgiant),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.lock_outline_rounded, color: AppColors.onPrimary),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                ),
                label: const Text(
                  'Pagar con PayPal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
