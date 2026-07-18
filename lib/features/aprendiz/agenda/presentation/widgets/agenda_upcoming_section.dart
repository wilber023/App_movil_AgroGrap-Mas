import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/agenda_activity_entity.dart';
import 'agenda_upcoming_task_tile.dart';

/// Seccion "Proximas tareas": actividades pendientes posteriores al dia
/// seleccionado, ordenadas cronologicamente.
class AgendaUpcomingSection extends StatelessWidget {
  final List<AgendaActivityEntity> upcomingActivities;
  final ValueChanged<DateTime> onTaskSelected;

  const AgendaUpcomingSection({
    super.key,
    required this.upcomingActivities,
    required this.onTaskSelected,
  });

  static const _dotColors = [AppColors.aOrange, AppColors.aSecondary, AppColors.aOrangeAccent];

  @override
  Widget build(BuildContext context) {
    if (upcomingActivities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxlPlus,
        AppSpacing.huge,
        AppSpacing.xxlPlus,
        AppSpacing.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Próximas tareas',
            style: AppTypography.agendaSectionTitle.copyWith(color: AppColors.aPrimary),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...upcomingActivities.asMap().entries.map((entry) {
            final i = entry.key;
            final activity = entry.value;
            return AgendaUpcomingTaskTile(
              activity: activity,
              dotColor: _dotColors[i % _dotColors.length],
              onTap: () => onTaskSelected(activity.scheduledDate),
            );
          }),
        ],
      ),
    );
  }
}
