import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
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
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.xxlPlus,
        AppSpacing.xxlPlus,
        AppSpacing.xxlPlus,
        AppSpacing.none,
      ),
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.aSecondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.lgXl),
            ),
            child: const Icon(Icons.eco, color: AppColors.aSecondary, size: 24),
          ),
          const SizedBox(width: AppSpacing.xxl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi cultivo actual',
                  style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  cropName,
                  style: AppTypography.agendaTitle.copyWith(color: AppColors.aPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
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
