import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'treatment_agenda_helpers.dart';

/// Encabezado de seccion (Vencidos / Hoy / Esta semana / Más adelante / ...)
/// usado en el filtro "Todos" de la Agenda Agronómica.
class AgendaSectionHeader extends StatelessWidget {
  final AgendaSection section;
  final int count;
  const AgendaSectionHeader({super.key, required this.section, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = sectionColor(section);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xsPlus),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(sectionIcon(section), size: 14, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          agendaSectionTitles[section]!,
          style: AppTypography.tituloMd.copyWith(
            color: AppColors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
          ),
          child: Text(
            '$count',
            style: AppTypography.etiquetaSm.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
