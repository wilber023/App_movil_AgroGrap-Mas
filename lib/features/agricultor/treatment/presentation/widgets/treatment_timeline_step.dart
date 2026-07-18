import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/treatment_entity.dart';
import '../bloc/treatment_bloc.dart';
import 'treatment_agenda_helpers.dart';

/// Paso individual de la línea de tiempo de un [TreatmentEntity]: indicador
/// circular de estado, título, fecha, descripción expandible y (si el paso
/// está programado) acciones de "Marcar completado" / "Reprogramar".
class TreatmentTimelineStep extends StatefulWidget {
  final TreatmentStepEntity step;
  final String treatmentId;
  final bool isLast;

  const TreatmentTimelineStep({
    super.key,
    required this.step,
    required this.treatmentId,
    required this.isLast,
  });

  @override
  State<TreatmentTimelineStep> createState() => _TreatmentTimelineStepState();
}

class _TreatmentTimelineStepState extends State<TreatmentTimelineStep> {
  bool _descriptionExpanded = false;

  TreatmentStepEntity get step => widget.step;
  String get treatmentId => widget.treatmentId;
  bool get isLast => widget.isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIndicatorColumn(),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? AppSpacing.none : AppSpacing.huge),
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorColumn() {
    return SizedBox(
      width: 28,
      child: Column(
        children: [
          _buildCircle(),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                color: step.isCompleted
                    ? AppColors.forestGreen.withValues(alpha: 0.4)
                    : AppColors.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircle() {
    if (step.isCompleted) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.statusHealthyBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: AppColors.forestGreen, size: 16),
      );
    }
    if (step.isOverdue) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.error, width: 2),
        ),
        child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 14),
      );
    }
    if (step.isScheduled) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.warmAmber.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.burntOrange, width: 2),
        ),
        child: const Icon(Icons.schedule_rounded, color: AppColors.burntOrange, size: 14),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant, width: 1.5),
      ),
      child: Center(
        child: Text(
          step.stepNumber.toString(),
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                step.title,
                style: AppTypography.labelMd.copyWith(
                  color: step.isCompleted
                      ? AppColors.onSurfaceVariant
                      : AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                  decoration:
                      step.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            _buildStatusChip(),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(
              step.isOverdue
                  ? Icons.error_outline_rounded
                  : Icons.calendar_today_outlined,
              size: 12,
              color: step.isOverdue ? AppColors.error : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                step.isOverdue
                    ? 'Atrasado ${step.daysOverdue} día${step.daysOverdue == 1 ? '' : 's'} '
                        '(${fmtShortDate(step.scheduledDate)})'
                    : (step.isCompleted && step.completedDate != null
                        ? 'Completado ${fmtShortDate(step.completedDate!)}'
                        : '${relativeDayLabel(step.scheduledDate)} · ${fmtShortDate(step.scheduledDate)}'),
                style: AppTypography.etiquetaSm.copyWith(
                  color: step.isOverdue ? AppColors.error : AppColors.onSurfaceVariant,
                  fontWeight: step.isOverdue ? FontWeight.w600 : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          step.description,
          maxLines: _descriptionExpanded ? null : 2,
          overflow: _descriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        if (step.description.length > descriptionCollapseThreshold)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _descriptionExpanded = !_descriptionExpanded),
              child: Text(
                _descriptionExpanded ? 'Ver menos' : 'Ver más',
                style: AppTypography.etiquetaSm.copyWith(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        if (step.isScheduled) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: () => _markComplete(context),
                    icon: const Icon(Icons.check_rounded, size: 15),
                    label: const Text('Marcar completado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: AppColors.white,
                      textStyle: AppTypography.etiquetaSm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.mdLg),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 34,
                height: 34,
                child: Tooltip(
                  message: 'Reprogramar',
                  child: OutlinedButton(
                    onPressed: () => _reschedule(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.forestGreen,
                      side: const BorderSide(color: AppColors.forestGreen),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.mdLg),
                      ),
                    ),
                    child: const Icon(Icons.event_repeat_rounded, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip() {
    if (step.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd, vertical: AppSpacing.xxsPlus),
        decoration: BoxDecoration(
          color: AppColors.statusHealthyBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          'Completado',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.forestGreen,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      );
    }
    if (step.isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd, vertical: AppSpacing.xxsPlus),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          'Vencido',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      );
    }
    if (step.isScheduled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd, vertical: AppSpacing.xxsPlus),
        decoration: BoxDecoration(
          color: AppColors.warmAmber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          'Próximo',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.burntOrange,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd, vertical: AppSpacing.xxsPlus),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        'En espera',
        style: AppTypography.etiquetaSm.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }

  void _markComplete(BuildContext context) {
    context.read<TreatmentBloc>().add(
          TreatmentStepCompleted(
            treatmentId: treatmentId,
            stepId: step.id,
          ),
        );
  }

  Future<void> _reschedule(BuildContext context) async {
    final bloc = context.read<TreatmentBloc>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Si el paso esta vencido, su fecha original queda antes de "hoy" y
    // showDatePicker exige initialDate >= firstDate: se ajusta a hoy.
    final initialDate =
        step.scheduledDate.isBefore(today) ? today : step.scheduledDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Nueva fecha',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (picked == null || !context.mounted) return;

    bloc.add(
      TreatmentStepRescheduled(
        treatmentId: treatmentId,
        stepId: step.id,
        newDate: picked,
      ),
    );
  }
}
