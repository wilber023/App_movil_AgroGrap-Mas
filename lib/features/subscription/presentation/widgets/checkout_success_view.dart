import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../utils/subscription_plans.dart';

/// Pantalla de éxito de [CheckoutPage] tras confirmar el pago.
class CheckoutSuccessView extends StatelessWidget {
  const CheckoutSuccessView({super.key, required this.plan, required this.onDone});

  final SubscriptionPlanInfo plan;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const ValueKey('success'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.huge,
          vertical: AppSpacing.xhuge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xgiant),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(scale: value, child: child),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.statusHealthyText,
                  size: 100,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xhuge),
            Text(
              '¡Pago Procesado\ncon Éxito!',
              style: AppTypography.tituloLg.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.giant),
            Container(
              padding: const EdgeInsets.all(AppSpacing.huge),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(AppRadius.xlPlus),
                border: Border.all(color: AppColors.outlineVariant, width: 0.5),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('Plan adquirido', plan.title, isHighlighted: true),
                  const Divider(height: AppSpacing.xhuge),
                  _buildReceiptRow('Monto pagado', plan.priceLabel),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xgiantPlus),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
                ),
                child: const Text(
                  'Listo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        ),
        const SizedBox(width: AppSpacing.xl),
        Text(
          value,
          style: AppTypography.labelMd.copyWith(
            color: isHighlighted ? AppColors.forestGreen : AppColors.onSurface,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
