import 'package:flutter/material.dart';

/// Metadata de planes para la UI. Los valores (precio, `id`) son los
/// documentados en API.md > "Planes y precios" -- exactamente dos planes.
class SubscriptionPlanInfo {
  final String id; // 'monthly' | 'yearly' -- valor exacto enviado a /subscribe
  final String title;
  final String priceLabel;
  final String? badge;
  final IconData icon;
  final bool recommended;
  final List<String> features;

  const SubscriptionPlanInfo({
    required this.id,
    required this.title,
    required this.priceLabel,
    this.badge,
    required this.icon,
    this.recommended = false,
    required this.features,
  });
}

abstract final class SubscriptionPlans {
  SubscriptionPlans._();

  static const free = SubscriptionPlanInfo(
    id: 'free',
    title: 'Gratuito',
    priceLabel: '\$0.00 / mes',
    icon: Icons.eco_outlined,
    features: [
      'Hasta 3 diagnósticos mensuales',
      'Gestión de 1 parcela',
      'Clima local básico',
    ],
  );

  static const monthly = SubscriptionPlanInfo(
    id: 'monthly',
    title: 'Premium',
    priceLabel: '\$9.99 / mes',
    icon: Icons.workspace_premium_rounded,
    features: [
      'Diagnósticos ilimitados con CNN avanzado',
      'Gestión de hasta 50 parcelas',
      'Alertas tempranas de plagas por IA',
      'Reportes económicos detallados',
      'Soporte prioritario',
    ],
  );

  static const yearly = SubscriptionPlanInfo(
    id: 'yearly',
    title: 'Premium Anual',
    priceLabel: '\$89.99 / año',
    badge: 'Ahorra 25%',
    icon: Icons.auto_awesome_rounded,
    recommended: true,
    features: [
      'Todas las ventajas del plan Premium',
      'Ahorro del 25% anual',
    ],
  );

  static SubscriptionPlanInfo byId(String id) => switch (id) {
        'monthly' => monthly,
        'yearly' => yearly,
        _ => free,
      };
}
