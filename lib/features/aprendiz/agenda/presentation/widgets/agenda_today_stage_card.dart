import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/agenda_activity_entity.dart';

/// Tarjeta principal de Agenda: resume la actividad/etapa del dia
/// seleccionado con su checklist y la accion "Marcar como completada".
class AgendaTodayStageCard extends StatelessWidget {
  final AgendaActivityEntity? activity;
  final DateTime selectedDay;
  final bool isProcessingAction;
  final VoidCallback onMarkCompleted;

  const AgendaTodayStageCard({
    super.key,
    required this.activity,
    required this.selectedDay,
    required this.isProcessingAction,
    required this.onMarkCompleted,
  });

  static const _weekdayNames = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];
  static const _monthNames = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  bool get _isToday {
    final now = DateTime.now();
    return selectedDay.year == now.year &&
        selectedDay.month == now.month &&
        selectedDay.day == now.day;
  }

  String get _dayLabel {
    final weekday = _weekdayNames[selectedDay.weekday - 1];
    final date = '${selectedDay.day} de ${_monthNames[selectedDay.month - 1]}';
    return _isToday ? 'Hoy · $weekday $date' : '$weekday $date';
  }

  @override
  Widget build(BuildContext context) {
    final current = activity;

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
      child: current == null
          ? _EmptyState(dayLabel: _dayLabel)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined, size: 18, color: AppColors.aOrange),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _dayLabel,
                      style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  current.title,
                  style: AppTypography.agendaTitle.copyWith(color: AppColors.aPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  current.description,
                  style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
                ),
                if (current.checklist.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  ...current.checklist.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check, size: 18, color: AppColors.aSecondary),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                item,
                                style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurface),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: AppSpacing.xxlPlus),
                if (current.status == AgendaActivityStatus.completed)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.aSecondary, size: 20),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'Completada',
                        style: AppTypography.agendaBody.copyWith(
                          color: AppColors.aSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isProcessingAction ? null : onMarkCompleted,
                      icon: isProcessingAction
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.aOnPrimary),
                            )
                          : const Icon(Icons.check_circle_outline, size: 20, color: AppColors.aOnPrimary),
                      label: Text(
                        'Marcar como completada',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.aOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.aSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String dayLabel;
  const _EmptyState({required this.dayLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.wb_sunny_outlined, size: 18, color: AppColors.aOrange),
            const SizedBox(width: AppSpacing.md),
            Text(
              dayLabel,
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.aSecondary, size: 20),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Text(
                'Sin actividades programadas para este día.',
                style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
