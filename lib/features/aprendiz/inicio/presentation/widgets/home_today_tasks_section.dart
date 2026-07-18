import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../agenda/domain/entities/agenda_activity_entity.dart';

/// Seccion "Tareas de hoy": actividades pendientes reales mas cercanas
/// (real, `GetAgendaOverviewUseCase`). La fecha se muestra en relativo
/// (Hoy/Mañana/dia de la semana) en vez de una hora inventada, ya que la
/// agenda no registra hora del dia, solo fecha.
class HomeTodayTasksSection extends StatelessWidget {
  final List<AgendaActivityEntity> tasks;
  final VoidCallback onViewCalendar;

  const HomeTodayTasksSection({super.key, required this.tasks, required this.onViewCalendar});

  String _relativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff < 0) return 'Atrasada';
    const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return weekdays[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tareas de hoy',
              style: AppTypography.agendaSectionTitle.copyWith(color: AppColors.aPrimary),
            ),
            GestureDetector(
              onTap: onViewCalendar,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ver calendario', style: AppTypography.etiquetaBold.copyWith(color: AppColors.aSecondary)),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.aSecondary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xxlPlus),
            decoration: BoxDecoration(
              color: AppColors.aSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.aOutlineVariant),
            ),
            child: Text(
              'No tienes tareas pendientes por ahora.',
              style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
            ),
          )
        else
          ...tasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _TaskRow(
                  task: task,
                  dayLabel: _relativeDay(task.scheduledDate),
                ),
              )),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final AgendaActivityEntity task;
  final String dayLabel;

  const _TaskRow({required this.task, required this.dayLabel});

  IconData get _icon => switch (task.category) {
        AgendaActivityCategory.inspection => Icons.search_rounded,
        AgendaActivityCategory.treatment => Icons.healing_outlined,
        AgendaActivityCategory.tracking => Icons.trending_up_rounded,
        AgendaActivityCategory.generic => Icons.event_note_outlined,
      };

  bool get _isImportant => task.category == AgendaActivityCategory.treatment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lgXl),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      child: Row(
        children: [
          Icon(_icon, size: 18, color: AppColors.aSecondary),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.agendaBody.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.aOnSurface,
                    ),
                  ),
                ),
                if (_isImportant) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.aWarningBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Importante',
                      style: AppTypography.etiquetaSm.copyWith(fontSize: 9, color: AppColors.aWarningText, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            dayLabel,
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.aOutline),
        ],
      ),
    );
  }
}
