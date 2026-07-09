import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 8,
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.aSecondary, size: 18),
              ),
              const SizedBox(width: 10),
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
