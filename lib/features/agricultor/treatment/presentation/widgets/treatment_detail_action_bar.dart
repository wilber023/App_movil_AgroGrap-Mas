import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/treatment_entity.dart';
import '../bloc/treatment_bloc.dart';

/// Barra de acciones de [TreatmentDetailPage]: "Editar fechas" / "Marcar
/// completo" sobre el paso activo, o mensaje de tratamiento completado.
class TreatmentDetailActionBar extends StatelessWidget {
  final TreatmentEntity treatment;
  const TreatmentDetailActionBar({super.key, required this.treatment});

  @override
  Widget build(BuildContext context) {
    final activeStep = treatment.activeStep;

    if (activeStep == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.statusHealthyBg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.forestGreen, size: 18),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Tratamiento completado',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => _editDates(context, activeStep),
              icon: const Icon(Icons.event_repeat_rounded, size: 17),
              label: const Text('Editar fechas'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.forestGreen,
                side: const BorderSide(color: AppColors.forestGreen),
                textStyle: AppTypography.etiquetaSm.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lgXl),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => _markComplete(context, activeStep),
              icon: const Icon(Icons.check_rounded, size: 17),
              label: const Text('Marcar completo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: AppColors.white,
                textStyle: AppTypography.etiquetaSm.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lgXl),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _markComplete(BuildContext context, TreatmentStepEntity activeStep) {
    context.read<TreatmentBloc>().add(
          TreatmentStepCompleted(
            treatmentId: treatment.id,
            stepId: activeStep.id,
          ),
        );
  }

  Future<void> _editDates(
    BuildContext context,
    TreatmentStepEntity activeStep,
  ) async {
    final bloc = context.read<TreatmentBloc>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate =
        activeStep.scheduledDate.isBefore(today) ? today : activeStep.scheduledDate;

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
        treatmentId: treatment.id,
        stepId: activeStep.id,
        newDate: picked,
      ),
    );
  }
}
