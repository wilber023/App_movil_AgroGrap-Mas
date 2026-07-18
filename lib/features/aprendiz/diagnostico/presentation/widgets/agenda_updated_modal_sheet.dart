import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../cultivo/domain/entities/crop_activity_entity.dart';

/// Modal de confirmación mostrado en [DiagnosisResultAprendizPage] cuando
/// aceptar la acción recomendada crea nuevas actividades en la agenda.
class AgendaUpdatedModalSheet extends StatelessWidget {
  const AgendaUpdatedModalSheet({
    super.key,
    required this.activities,
    required this.onViewAgenda,
  });

  final List<CropActivityEntity> activities;
  final VoidCallback onViewAgenda;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xhuge)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xhuge,
        AppSpacing.xhuge,
        AppSpacing.xhuge,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xhuge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.xhuge),
            decoration: BoxDecoration(
              color: AppColors.aOutlineVariant,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(
              color: AppColors.aSecondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, size: 36, color: AppColors.aSecondary),
          ),
          const SizedBox(height: AppSpacing.xxlPlus),
          Text(
            '¡Agenda actualizada!',
            style: AppTypography.agendaTitle.copyWith(color: AppColors.aOnSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Se crearon ${activities.length} actividades en tu agenda:',
            style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.huge),
          ...activities.take(3).map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.aOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Text(
                      a.title,
                      style: AppTypography.agendaBody.copyWith(fontWeight: FontWeight.w500, color: AppColors.aOnSurface),
                    ),
                  ),
                  Text(
                    '${a.scheduledDate.day}/${a.scheduledDate.month}',
                    style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xhuge),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onViewAgenda,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.aOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
                elevation: 0,
              ),
              child: Text(
                'Ver mi agenda',
                style: AppTypography.agendaTitle.copyWith(fontSize: 16, color: AppColors.aOnPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
