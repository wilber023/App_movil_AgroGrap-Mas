import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
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
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppColors.aSecondary),
              const SizedBox(width: 8),
              Text(
                recommendation.title,
                style: AppTypography.agendaSectionTitle.copyWith(fontSize: 15, color: AppColors.aPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.description,
            style: AppTypography.agendaBody.copyWith(fontSize: 13, color: AppColors.aOnSurfaceVariant, height: 1.4),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.aSecondary),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
