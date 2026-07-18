import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/agenda_activity_entity.dart';

/// Fila de una tarea futura dentro de "Proximas tareas": punto de color,
/// chip con icono segun categoria, fecha, titulo y chevron.
class AgendaUpcomingTaskTile extends StatelessWidget {
  final AgendaActivityEntity activity;
  final Color dotColor;
  final VoidCallback onTap;

  const AgendaUpcomingTaskTile({
    super.key,
    required this.activity,
    required this.dotColor,
    required this.onTap,
  });

  static const _monthShort = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  IconData get _categoryIcon {
    switch (activity.category) {
      case AgendaActivityCategory.inspection:
        return Icons.camera_alt_outlined;
      case AgendaActivityCategory.tracking:
        return Icons.calendar_today_outlined;
      case AgendaActivityCategory.treatment:
        return Icons.medical_services_outlined;
      case AgendaActivityCategory.generic:
        return Icons.event_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${activity.scheduledDate.day} ${_monthShort[activity.scheduledDate.month - 1]}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.aSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: Border.all(color: AppColors.aOutlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xl),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.aSurfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.mdLg),
              ),
              child: Icon(_categoryIcon, size: 18, color: AppColors.aOnSurfaceVariant),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Text(
                '$dateStr · ${activity.title}',
                style: AppTypography.agendaBody.copyWith(
                  color: AppColors.aOnSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.aOutline),
          ],
        ),
      ),
    );
  }
}
