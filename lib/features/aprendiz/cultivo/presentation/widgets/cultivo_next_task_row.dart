import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Fila "Proxima tarea": titulo de la siguiente actividad pendiente y su
/// fecha programada.
class CultivoNextTaskRow extends StatelessWidget {
  final String taskTitle;
  final DateTime scheduledDate;
  final VoidCallback onTap;

  const CultivoNextTaskRow({
    super.key,
    required this.taskTitle,
    required this.scheduledDate,
    required this.onTap,
  });

  static const _monthShort = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${scheduledDate.day} ${_monthShort[scheduledDate.month - 1]} ${scheduledDate.year}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxlPlus,
          vertical: AppSpacing.xxl,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.aSurfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.mdLg),
              ),
              child: const Icon(Icons.event_note_outlined, color: AppColors.aSecondary, size: 20),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próxima tarea',
                    style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    taskTitle,
                    style: AppTypography.agendaBody.copyWith(
                      color: AppColors.aOnSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              dateStr,
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.aSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.aOutline),
          ],
        ),
      ),
    );
  }
}
