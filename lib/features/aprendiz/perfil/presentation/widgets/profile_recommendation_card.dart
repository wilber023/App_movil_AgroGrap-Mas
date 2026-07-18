import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/aprendiz_recommendation_entity.dart';

/// Tarjeta de recomendacion personalizada, con boton opcional para navegar
/// a la seccion sugerida (ver `RecommendationAction`).
class ProfileRecommendationCard extends StatelessWidget {
  final AprendizRecommendationEntity recommendation;
  final VoidCallback? onAction;

  const ProfileRecommendationCard({super.key, required this.recommendation, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.aLightGreen,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppColors.aSecondary),
              const SizedBox(width: AppSpacing.md),
              Text(
                recommendation.title,
                style: AppTypography.agendaSectionTitle.copyWith(fontSize: 15, color: AppColors.aPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            recommendation.description,
            style: AppTypography.agendaBody.copyWith(fontSize: 13, color: AppColors.aOnSurfaceVariant, height: 1.4),
          ),
          if (onAction != null) ...[
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
                  recommendation.actionLabel,
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
