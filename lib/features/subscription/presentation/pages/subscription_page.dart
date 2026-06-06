import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/shared_components.dart';
import 'checkout_page.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Planes y Suscripciones'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Potencia tu Cultivo con AgroGraph Premium',
              style: AppTypography.tituloLg.copyWith(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Desbloquea diagnosticos ilimitados, predicciones climaticas avanzadas y gestion de hasta 50 parcelas simultaneas.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildPlanCard(
              context: context,
              title: 'Gratuito',
              price: '\$0.00 / mes',
              features: [
                'Hasta 3 diagnosticos mensuales',
                'Gestion de 1 parcela',
                'Clima local basico',
              ],
              isPremium: false,
              isActive: true,
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              context: context,
              title: 'Premium',
              price: '\$9.99 / mes',
              features: [
                'Diagnosticos ilimitados con CNN avanzado',
                'Gestion de hasta 50 parcelas',
                'Alertas tempranas de plagas por IA',
                'Reportes economicos detallados',
                'Soporte prioritario',
              ],
              isPremium: true,
              isActive: false,
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              context: context,
              title: 'Anual Premium',
              price: '\$89.99 / ano',
              features: [
                'Todas las ventajas del plan Premium',
                'Ahorro del 25% anual',
              ],
              isPremium: true,
              isActive: false,
            ),
            const SizedBox(height: 32),
            const Text(
              'Las suscripciones se renuevan automaticamente. Puedes cancelar en cualquier momento desde los ajustes de tu cuenta.',
              style: AppTypography.etiquetaSm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String price,
    required List<String> features,
    required bool isPremium,
    required bool isActive,
  }) {
    final borderColor = isPremium ? AppColors.primary : AppColors.cardBorder;
    final bgColor = isPremium ? AppColors.primaryContainer.withValues(alpha: 0.1) : AppColors.cardSurface;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isPremium ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.tituloMd.copyWith(
                  color: isPremium ? AppColors.primary : AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isActive)
                StatusPill(
                  label: 'Plan Actual',
                  background: AppColors.statusHealthyBg,
                  textColor: AppColors.statusHealthyText,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            price,
            style: AppTypography.tituloLg.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 24),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: isPremium ? AppColors.primary : AppColors.forestGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          if (!isActive)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (isPremium) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckoutPage()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPremium ? AppColors.primary : AppColors.surfaceContainerHigh,
                  foregroundColor: isPremium ? Colors.white : AppColors.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isPremium ? 'Mejorar ahora' : 'Seleccionar',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
