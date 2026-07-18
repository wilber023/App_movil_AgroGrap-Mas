import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Banner hero de [SubscriptionPage] ("Potencia tu Cultivo con AgroGraph
/// Premium").
class SubscriptionHeroBanner extends StatelessWidget {
  const SubscriptionHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxhuge,
        horizontal: AppSpacing.huge,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.forestGreen],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.onPrimary, size: 26),
          ),
          const SizedBox(height: AppSpacing.xxlPlus),
          Text(
            'Potencia tu Cultivo con AgroGraph Premium',
            style: AppTypography.tituloLg.copyWith(color: AppColors.onPrimary, fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Desbloquea diagnósticos ilimitados, predicciones climáticas avanzadas y gestión de hasta 50 parcelas simultáneas.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.9)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
