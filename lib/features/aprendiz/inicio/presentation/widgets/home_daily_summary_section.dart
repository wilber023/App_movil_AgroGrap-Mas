import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/crop_status_summary_entity.dart';

/// Seccion "Resumen del día": 4 estadisticas reales derivadas del cultivo y
/// la agenda del usuario, mas un banner motivacional derivado del progreso
/// y la salud reales (nunca texto fijo desconectado del estado real).
class HomeDailySummarySection extends StatelessWidget {
  final int pendingTasksCount;
  final CropStatusSummaryEntity cropStatus;

  const HomeDailySummarySection({
    super.key,
    required this.pendingTasksCount,
    required this.cropStatus,
  });

  String? get _motivationalMessage {
    if (!cropStatus.hasCropPlan) return null;
    final progress = cropStatus.progressPercentage ?? 0;
    final health = cropStatus.healthStatus;
    if (health == 'Crítico') {
      return 'Tu cultivo necesita atención: revisa la alerta epidemiológica y las tareas de hoy.';
    }
    if (progress >= 50 || health == 'Saludable') {
      return '¡Vas bien! Continúa así para lograr una excelente cosecha.';
    }
    return 'Sigue registrando tus actividades para mantener tu cultivo en buen camino.';
  }

  @override
  Widget build(BuildContext context) {
    final progress = cropStatus.progressPercentage;
    final health = cropStatus.healthStatus;
    final message = _motivationalMessage;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen del día',
          style: AppTypography.agendaSectionTitle.copyWith(color: AppColors.aPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.checklist_rounded,
                iconColor: AppColors.aSecondary,
                value: '$pendingTasksCount',
                label: pendingTasksCount == 1 ? 'Tarea pendiente' : 'Tareas pendientes',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.calendar_today_rounded,
                iconColor: AppColors.aOrange,
                value: cropStatus.currentWeek != null ? '${cropStatus.currentWeek}' : '—',
                label: 'Semana actual',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.infoBlue,
                value: progress != null ? '${progress.toInt()}%' : '—',
                label: 'Progreso del ciclo',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.eco_rounded,
                iconColor: AppColors.aSecondary,
                value: health ?? 'Sin datos',
                label: 'Salud general',
                small: health != null && health.length > 6,
              ),
            ),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.aWarningBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.aWarningBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.emoji_events_outlined, size: 18, color: AppColors.aWarningText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: AppTypography.etiquetaSm.copyWith(color: AppColors.aWarningText, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool small;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.etiquetaBold.copyWith(
              fontSize: small ? 12 : 14,
              color: AppColors.aOnSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTypography.etiquetaSm.copyWith(fontSize: 10, color: AppColors.aOnSurfaceVariant, height: 1.15),
          ),
        ],
      ),
    );
  }
}
