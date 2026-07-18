import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/aprendiz_activity_summary_entity.dart';

/// Tarjeta de resumen de actividad: grid compacto de 4 estadisticas.
class ProfileActivitySummaryCard extends StatelessWidget {
  final AprendizActivitySummaryEntity summary;

  const ProfileActivitySummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final stats = [
      (Icons.eco_outlined, '${summary.cropsRegistered}', 'Cultivos\nregistrados'),
      (Icons.psychology_outlined, '${summary.diagnosesCompleted}', 'Diagnósticos\nrealizados'),
      (Icons.task_alt, '${summary.activitiesCompleted}', 'Actividades\ncompletadas'),
      (Icons.calendar_today_outlined, '${summary.daysLearning}', 'Días\naprendiendo'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.xxl,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.6,
        children: stats.map((s) {
          final (icon, value, label) = s;
          return Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.aSecondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.mdLg),
                ),
                child: Icon(icon, color: AppColors.aSecondary, size: 18),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: AppTypography.agendaTitle.copyWith(fontSize: 18, color: AppColors.aOnSurface),
                    ),
                    Text(
                      label,
                      style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant, height: 1.1),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
