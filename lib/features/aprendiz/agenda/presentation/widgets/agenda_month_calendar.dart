import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/agenda_activity_entity.dart';

/// Calendario de Agenda: encabezado de mes navegable + semana visible con
/// indicadores de actividad. Puramente presentacional: toda la logica de
/// que semana/mes mostrar vive en [AgendaBloc] (ver `visibleMonth`/`selectedDay`).
class AgendaMonthCalendar extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime visibleMonth;
  final List<AgendaActivityEntity> activities;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const AgendaMonthCalendar({
    super.key,
    required this.selectedDay,
    required this.visibleMonth,
    required this.activities,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  static const _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const _weekdayInitials = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

  DateTime _mondayOf(DateTime day) => day.subtract(Duration(days: day.weekday - 1));

  int _daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  AgendaActivityEntity? _activityFor(DateTime day) {
    for (final activity in activities) {
      if (_isSameDay(activity.scheduledDate, day)) return activity;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final clampedDay = selectedDay.day.clamp(1, _daysInMonth(visibleMonth));
    final anchor = DateTime(visibleMonth.year, visibleMonth.month, clampedDay);
    final weekStart = _mondayOf(anchor);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Container(
      color: AppColors.aSurfaceContainerLowest,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.aOnSurfaceVariant),
                onPressed: onPreviousMonth,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                '${_monthNames[visibleMonth.month - 1]} ${visibleMonth.year}',
                style: AppTypography.agendaSubtitle.copyWith(color: AppColors.aOnSurface),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.aOnSurfaceVariant),
                onPressed: onNextMonth,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final day = days[i];
                final isToday = _isSameDay(day, now);
                final isSelected = _isSameDay(day, selectedDay);
                final activity = _activityFor(day);

                return GestureDetector(
                  onTap: () => onDaySelected(day),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        Text(
                          _weekdayInitials[i],
                          style: AppTypography.etiquetaSm.copyWith(
                            color: AppColors.aOnSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppColors.aPrimaryContainer : Colors.transparent,
                            border: isToday && !isSelected
                                ? Border.all(color: AppColors.aSecondary, width: 1.5)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: AppTypography.agendaSubtitle.copyWith(
                                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.aOnPrimary
                                    : isToday
                                        ? AppColors.aSecondary
                                        : AppColors.aOnSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: activity == null
                                ? Colors.transparent
                                : activity.status == AgendaActivityStatus.completed
                                    ? AppColors.aSecondary
                                    : AppColors.aOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
