import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../treatment/domain/entities/treatment_entity.dart';
import '../../../treatment/presentation/bloc/treatment_bloc.dart';
import 'home_section_header.dart';

/// Sección "Tareas programadas" de HomePage — misma fuente que la Agenda.
/// No se muestran horas de reloj (10:00 AM, etc.) porque los tratamientos no
/// tienen una hora programada real, solo fecha — mostrarlas seria inventar
/// un dato.
class HomeTodayTasksSection extends StatelessWidget {
  const HomeTodayTasksSection({super.key, required this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TreatmentBloc, TreatmentState>(
      builder: (context, state) {
        final treatments = state is TreatmentAgendaLoaded ? state.treatments : const <TreatmentEntity>[];
        final pending = treatments.where((t) => t.activeStep != null).toList()
          ..sort((a, b) {
            int rank(TreatmentEntity t) => t.isOverdue ? 0 : (t.isDueToday ? 1 : 2);
            final r = rank(a).compareTo(rank(b));
            if (r != 0) return r;
            return a.activeStep!.scheduledDate.compareTo(b.activeStep!.scheduledDate);
          });
        final display = pending.take(3).toList();

        if (display.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionHeader(
              title: 'Tareas programadas',
              action: 'Ver todas',
              onTap: () => onNavigateToTab?.call(3),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.onPrimary,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < display.length; i++)
                    _TaskRow(
                      treatment: display[i],
                      isLast: i == display.length - 1,
                      onTap: () => onNavigateToTab?.call(3),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TreatmentEntity treatment;
  final bool isLast;
  final VoidCallback onTap;
  const _TaskRow({required this.treatment, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final String badgeLabel;
    if (treatment.isOverdue) {
      dotColor = AppColors.error;
      badgeLabel = 'Vencida';
    } else if (treatment.isDueToday) {
      dotColor = AppColors.burntOrange;
      badgeLabel = 'Hoy';
    } else {
      dotColor = AppColors.forestGreen;
      badgeLabel = 'Mañana';
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    treatment.activeStep!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    treatment.diseaseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxsPlus),
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                badgeLabel,
                style: AppTypography.etiquetaSm.copyWith(
                  color: dotColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
