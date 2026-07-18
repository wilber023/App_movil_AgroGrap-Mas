import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Campo de fecha del formulario de registro: icono calendario, texto
/// (placeholder o fecha formateada) y chevron.
class CultivoDateField extends StatelessWidget {
  final DateTime? selectedDate;
  final String Function(DateTime date) formatDate;
  final VoidCallback onTap;

  const CultivoDateField({
    super.key,
    required this.selectedDate,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.aSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.mdLg),
          border: Border.all(
            color: hasDate ? AppColors.aSecondary : AppColors.aOutlineVariant,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxlPlus,
          vertical: AppSpacing.xxl,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: AppColors.aOnSurfaceVariant, size: 20),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Text(
                hasDate ? formatDate(selectedDate!) : 'Seleccionar fecha',
                style: AppTypography.agendaBody.copyWith(
                  color: hasDate ? AppColors.aOnSurface : AppColors.aOnSurfaceVariant,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.aOnSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}
