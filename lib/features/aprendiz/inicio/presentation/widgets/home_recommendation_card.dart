import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
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
      decoration: BoxDecoration(color: AppColors.aLightGreen, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppColors.aSecondary),
              const SizedBox(width: 8),
              Text(
                'Recomendación del día',
                style: AppTypography.agendaSectionTitle.copyWith(fontSize: 15, color: AppColors.aPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.message,
            style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
          ),
          if (showAction) ...[
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
