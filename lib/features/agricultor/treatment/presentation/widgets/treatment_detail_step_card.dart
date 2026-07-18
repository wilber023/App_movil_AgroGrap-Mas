import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/treatment_entity.dart';
import 'treatment_detail_helpers.dart';

/// Tarjeta de un paso del plan de tratamiento en [TreatmentDetailPage]:
/// indicador circular de estado, título, fecha, descripción y badge.
class TreatmentDetailStepCard extends StatelessWidget {
  final TreatmentStepEntity step;
  final bool isLast;
  final bool isImmediateNext;

  const TreatmentDetailStepCard({
    super.key,
    required this.step,
    required this.isLast,
    required this.isImmediateNext,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIndicatorColumn(),
          const SizedBox(width: AppSpacing.xl),
          Expanded(child: _buildCard()),
        ],
      ),
    );
  }

  Widget _buildIndicatorColumn() {
    return SizedBox(
      width: 32,
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
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.statusHealthyBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: AppColors.forestGreen, size: 18),
      );
    }
    if (step.isOverdue) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.error, width: 2),
        ),
        child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
      );
    }
    if (step.isScheduled) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: AppColors.forestGreen, shape: BoxShape.circle),
        child: Center(
          child: Text(
            '${step.stepNumber}',
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant, width: 1.5),
      ),
      child: Center(
        child: Text(
          '${step.stepNumber}',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  step.title,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    decoration:
                        step.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                step.isCompleted && step.completedDate != null
                    ? detailFmtShort(step.completedDate!)
                    : detailRelativeDayLabel(step.scheduledDate),
                style: AppTypography.etiquetaSm.copyWith(
                  color: step.isOverdue ? AppColors.error : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            detailFmtShort(step.scheduledDate),
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: _boxColor().withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.lgXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildStatusChip(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _boxColor() {
    if (step.isCompleted) return AppColors.forestGreen;
    if (step.isOverdue) return AppColors.error;
    if (step.isScheduled) return AppColors.forestGreen;
    return AppColors.outline;
  }

  Widget _buildStatusChip() {
    final String label;
    final Color color;
    if (step.isCompleted) {
      label = 'Completado';
      color = AppColors.forestGreen;
    } else if (step.isOverdue) {
      label = 'Vencido';
      color = AppColors.error;
    } else if (step.isScheduled) {
      label = 'Programado';
      color = AppColors.forestGreen;
    } else if (isImmediateNext) {
      label = 'Próximo';
      color = AppColors.infoBlue;
    } else {
      label = 'Pendiente';
      color = AppColors.onSurfaceVariant;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          step.isCompleted ? Icons.check_circle_rounded : Icons.circle,
          size: 10,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.etiquetaSm.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
