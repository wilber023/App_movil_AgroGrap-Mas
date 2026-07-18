import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../subscription/presentation/pages/subscription_page.dart';

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
        borderRadius: BorderRadius.circular(AppRadius.lgXl),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.aSecondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'PLAN FREE',
                  style: AppTypography.statusPill.copyWith(color: AppColors.aOnSecondaryContainer),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(context, SubscriptionPage.route()),
                child: Text(
                  'Conocer Pro →',
                  style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOrange, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ..._benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 14, color: AppColors.aSecondary),
                  const SizedBox(width: AppSpacing.md),
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
