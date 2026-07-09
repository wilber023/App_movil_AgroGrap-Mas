import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Tarjeta de suscripcion, compacta y poco invasiva: plan actual,
/// beneficios disponibles y una unica opcion para conocer AgroGraph Pro.
class ProfileSubscriptionCard extends StatelessWidget {
  const ProfileSubscriptionCard({super.key});

  static const _benefits = [
    'Diagnósticos ilimitados',
    'Historial completo de aprendizaje',
    'Recordatorios de agenda',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.aSecondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PLAN FREE',
                  style: AppTypography.statusPill.copyWith(color: AppColors.aOnSecondaryContainer),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Conocer Pro →',
                  style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOrange, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 14, color: AppColors.aSecondary),
                  const SizedBox(width: 8),
                  Text(b, style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
