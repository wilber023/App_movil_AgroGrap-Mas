import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/weekly_goal_entity.dart';

/// Tarjeta de objetivo semanal: lista de metas con barra de progreso.
class ProfileWeeklyGoalCard extends StatelessWidget {
  final List<WeeklyGoalEntity> goals;

  const ProfileWeeklyGoalCard({super.key, required this.goals});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, size: 18, color: AppColors.aSecondary),
              const SizedBox(width: 8),
              Text(
                'Objetivo semanal',
                style: AppTypography.agendaSectionTitle.copyWith(fontSize: 16, color: AppColors.aOnSurface),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...goals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          goal.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 16,
                          color: goal.isCompleted ? AppColors.aSecondary : AppColors.aOnSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            goal.label,
                            style: AppTypography.agendaBody.copyWith(fontSize: 13, color: AppColors.aOnSurface),
                          ),
                        ),
                        Text(
                          '${goal.current}/${goal.target}',
                          style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 6,
                        backgroundColor: AppColors.aSurfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          goal.isCompleted ? AppColors.aSecondary : AppColors.aOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
