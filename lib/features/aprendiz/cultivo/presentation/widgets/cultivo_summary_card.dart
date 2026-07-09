import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Tarjeta "Mi cultivo actual": nombre del cultivo y semana dentro del
/// ciclo total de [totalWeeks] semanas.
class CultivoSummaryCard extends StatelessWidget {
  final String cropName;
  final int currentWeek;
  final int totalWeeks;

  const CultivoSummaryCard({
    super.key,
    required this.cropName,
    required this.currentWeek,
    required this.totalWeeks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.aSecondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.eco, color: AppColors.aSecondary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi cultivo actual',
                  style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  cropName,
                  style: AppTypography.agendaTitle.copyWith(color: AppColors.aPrimary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.aSecondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Semana $currentWeek de $totalWeeks',
                    style: AppTypography.etiquetaSm.copyWith(
                      color: AppColors.aOnSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.aOutline),
        ],
      ),
    );
  }
}
