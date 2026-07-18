import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../treatment/domain/entities/treatment_entity.dart';
import '../../../treatment/presentation/bloc/treatment_bloc.dart';
import 'home_section_header.dart';

/// Resumen de tratamientos de hoy en HomePage — reutiliza TreatmentBloc
/// (misma fuente que la Agenda).
class HomeTodaySummary extends StatelessWidget {
  const HomeTodaySummary({super.key, required this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TreatmentBloc, TreatmentState>(
      builder: (context, state) {
        final treatments = state is TreatmentAgendaLoaded ? state.treatments : const <TreatmentEntity>[];
        final overdue = treatments.where((t) => t.isOverdue).length;
        final today = treatments.where((t) => t.isDueToday).length;
        final week = treatments.where((t) => t.isDueThisWeek).length;
        final completed = treatments.where((t) => t.activeStep == null).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionHeader(
              title: 'Resumen de hoy',
              action: 'Ver agenda',
              onTap: () => onNavigateToTab?.call(3),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _HomeStat(
                    count: overdue,
                    label: 'Vencidos',
                    color: AppColors.error,
                    icon: Icons.error_outline_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _HomeStat(
                    count: today,
                    label: 'Hoy',
                    color: AppColors.burntOrange,
                    icon: Icons.event_note_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _HomeStat(
                    count: week,
                    label: 'Esta semana',
                    color: AppColors.forestGreen,
                    icon: Icons.eco_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _HomeStat(
                    count: completed,
                    label: 'Completados',
                    color: AppColors.infoBlue,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HomeStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  const _HomeStat({required this.count, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$count',
            style: AppTypography.headlineMd.copyWith(color: color, fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
