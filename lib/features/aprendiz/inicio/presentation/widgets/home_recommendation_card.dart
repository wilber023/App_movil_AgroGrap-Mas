import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/home_recommendation_entity.dart';

/// Tarjeta de recomendacion del dia: regla simple y real, propia de Inicio
/// (no reutiliza la logica de recomendaciones de Perfil).
class HomeRecommendationCard extends StatelessWidget {
  final HomeRecommendationEntity recommendation;
  final VoidCallback? onAction;

  const HomeRecommendationCard({super.key, required this.recommendation, this.onAction});

  String get _actionLabel {
    switch (recommendation.action) {
      case HomeRecommendationAction.registerCrop:
        return 'Registrar cultivo';
      case HomeRecommendationAction.diagnosis:
        return 'Realizar diagnóstico';
      case HomeRecommendationAction.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAction = recommendation.action != HomeRecommendationAction.none && onAction != null;

    return Container(
      decoration: BoxDecoration(color: AppColors.aLightGreen, borderRadius: BorderRadius.circular(AppRadius.xlPlus)),
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppColors.aSecondary),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Recomendación del día',
                style: AppTypography.agendaSectionTitle.copyWith(fontSize: 15, color: AppColors.aPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            recommendation.message,
            style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
          ),
          if (showAction) ...[
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.aSecondary),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mdLg)),
                ),
                child: Text(
                  _actionLabel,
                  style: AppTypography.labelMd.copyWith(color: AppColors.aSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
