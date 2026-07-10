import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Tarjeta "Aprende hoy": muestra la explicacion educativa
/// (`llmResponse.explicacion`) del diagnostico mas reciente, si existe. Si
/// el usuario aun no tiene ningun diagnostico con explicacion, no se
/// renderiza — no se inventa contenido educativo que la API no genero.
class HomeFunFactCard extends StatelessWidget {
  final String? funFact;
  final VoidCallback onViewMore;

  const HomeFunFactCard({super.key, required this.funFact, required this.onViewMore});

  @override
  Widget build(BuildContext context) {
    final fact = funFact;
    if (fact == null || fact.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.aTertiaryFixed,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.aOnTertiaryFixedVariant.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 18, color: AppColors.aOnTertiaryFixedVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aprende hoy',
                  style: AppTypography.agendaSectionTitle.copyWith(fontSize: 14, color: AppColors.aOnTertiaryFixedVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fact,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnTertiaryFixedVariant, height: 1.3),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onViewMore,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver lección',
                  style: AppTypography.etiquetaBold.copyWith(color: AppColors.aOnTertiaryFixedVariant),
                ),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.aOnTertiaryFixedVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
