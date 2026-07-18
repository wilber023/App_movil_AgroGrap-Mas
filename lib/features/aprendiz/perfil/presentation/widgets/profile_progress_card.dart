import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/aprendiz_progress_entity.dart';

/// Tarjeta de progreso: nivel, XP, racha y avance hacia el siguiente nivel.
class ProfileProgressCard extends StatelessWidget {
  final AprendizProgressEntity progress;

  const ProfileProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.aPrimaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nivel ${progress.level}',
                      style: AppTypography.agendaTitle.copyWith(color: AppColors.aOnPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${progress.xp} XP acumulada',
                      style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnPrimaryContainer),
                    ),
                  ],
                ),
              ),
              _StreakBadge(days: progress.streakDays),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress.progressToNextLevel,
              minHeight: 8,
              backgroundColor: AppColors.aOnPrimaryContainer.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.aOrangeAccent),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Progreso al nivel ${progress.level + 1}',
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int days;
  const _StreakBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.aOnPrimaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.aOrangeAccent, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$days ${days == 1 ? 'día' : 'días'}',
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnPrimary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
