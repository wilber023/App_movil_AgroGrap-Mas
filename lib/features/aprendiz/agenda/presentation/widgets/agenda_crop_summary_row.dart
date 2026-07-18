import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/agenda_crop_context_entity.dart';

/// Fila "Mi cultivo: nombre" + pill "Semana N" mostrada bajo el calendario.
class AgendaCropSummaryRow extends StatelessWidget {
  final AgendaCropContextEntity cropContext;

  const AgendaCropSummaryRow({super.key, required this.cropContext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxlPlus,
        AppSpacing.xxlPlus,
        AppSpacing.xxlPlus,
        AppSpacing.none,
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_outlined, size: 18, color: AppColors.aSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.agendaSubtitle.copyWith(color: AppColors.aOnSurfaceVariant),
                children: [
                  const TextSpan(text: 'Mi cultivo: '),
                  TextSpan(
                    text: cropContext.cropName,
                    style: const TextStyle(
                      color: AppColors.aPrimary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.aSecondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              'Semana ${cropContext.currentWeek}',
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.aOnSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
