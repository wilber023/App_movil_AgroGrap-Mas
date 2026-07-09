import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Tarjeta "HOY": resume la etapa actual del cultivo y enlaza a la Agenda
/// para ver el detalle del dia (checklist y accion de completar viven ahi,
/// no se duplican en esta pantalla).
class CultivoTodayStageCard extends StatelessWidget {
  final int currentWeek;
  final String stageName;
  final String stageDescription;
  final VoidCallback onViewTodayTask;

  const CultivoTodayStageCard({
    super.key,
    required this.currentWeek,
    required this.stageName,
    required this.stageDescription,
    required this.onViewTodayTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.aLightGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOY · Semana $currentWeek',
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.aOnPrimaryFixedVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stageName,
            style: AppTypography.agendaTitle.copyWith(color: AppColors.aPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            stageDescription,
            style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewTodayTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.aSecondary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ver tarea de hoy',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.aOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18, color: AppColors.aOnPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
