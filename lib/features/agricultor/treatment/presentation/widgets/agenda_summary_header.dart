import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/treatment_entity.dart';
import 'agenda_hero_card.dart';

/// Resumen del día de la Agenda Agronómica: [AgendaHeroCard] + fila de
/// conteos (vencidas / hoy / esta semana / completadas).
class AgendaSummaryHeader extends StatelessWidget {
  final List<TreatmentEntity> treatments;
  const AgendaSummaryHeader({super.key, required this.treatments});

  @override
  Widget build(BuildContext context) {
    final overdue = treatments.where((t) => t.isOverdue).length;
    final today = treatments.where((t) => t.isDueToday).length;
    final week = treatments.where((t) => t.isDueThisWeek).length;
    final completed = treatments.where((t) => t.activeStep == null).length;
    final allClear = overdue == 0 && today == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AgendaHeroCard(allClear: allClear),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  count: overdue,
                  label: 'Vencidas',
                  color: AppColors.error,
                  icon: Icons.error_outline_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _SummaryStat(
                  count: today,
                  label: 'Hoy',
                  color: AppColors.burntOrange,
                  icon: Icons.today_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _SummaryStat(
                  count: week,
                  label: 'Esta semana',
                  color: AppColors.forestGreen,
                  icon: Icons.date_range_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _SummaryStat(
                  count: completed,
                  label: 'Completadas',
                  color: AppColors.infoBlue,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryStat({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: AppSpacing.xsPlus),
          Text(
            '$count',
            style: AppTypography.headlineMd.copyWith(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
