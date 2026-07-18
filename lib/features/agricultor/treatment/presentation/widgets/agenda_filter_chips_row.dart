import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/treatment_entity.dart';
import 'treatment_agenda_helpers.dart';

/// Fila de chips de filtro (Todos / Hoy / Semana / Vencidos) de la Agenda
/// Agronómica, con conteo por categoría.
class AgendaFilterChipsRow extends StatelessWidget {
  final AgendaFilter selected;
  final List<TreatmentEntity> treatments;
  final ValueChanged<AgendaFilter> onSelected;

  const AgendaFilterChipsRow({
    super.key,
    required this.selected,
    required this.treatments,
    required this.onSelected,
  });

  static const _labels = {
    AgendaFilter.todos: 'Todos',
    AgendaFilter.hoy: 'Hoy',
    AgendaFilter.semana: 'Semana',
    AgendaFilter.vencidos: 'Vencidos',
  };

  int _countFor(AgendaFilter f) {
    switch (f) {
      case AgendaFilter.todos:
        return treatments.length;
      case AgendaFilter.hoy:
        return treatments.where((t) => t.isDueToday).length;
      case AgendaFilter.semana:
        return treatments.where((t) => t.isDueThisWeek).length;
      case AgendaFilter.vencidos:
        return treatments.where((t) => t.isOverdue).length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AgendaFilter.values.map((f) {
          final isSelected = f == selected;
          final isVencidos = f == AgendaFilter.vencidos;
          final count = _countFor(f);
          final label = count > 0 ? '${_labels[f]} · $count' : _labels[f]!;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onSelected(f),
              labelStyle: AppTypography.etiquetaSm.copyWith(
                color: isSelected
                    ? AppColors.white
                    : (isVencidos && count > 0
                        ? AppColors.error
                        : AppColors.onSurfaceVariant),
                fontWeight: FontWeight.w600,
              ),
              selectedColor:
                  isVencidos ? AppColors.error : AppColors.forestGreen,
              backgroundColor: AppColors.surfaceContainerLow,
              side: BorderSide(
                color: isVencidos && count > 0 && !isSelected
                    ? AppColors.error.withValues(alpha: 0.4)
                    : AppColors.outlineVariant,
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
