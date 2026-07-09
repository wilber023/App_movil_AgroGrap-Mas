import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Campo opcional para describir lo que el aprendiz observa en la planta.
/// Incluye un texto de ayuda que explica por que vale la pena completarlo.
class DiagnosisDescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final bool isEnabled;

  const DiagnosisDescriptionField({
    super.key,
    required this.controller,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Describe lo que observas (opcional)',
          style: AppTypography.etiquetaBold.copyWith(color: AppColors.aOnSurface),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 300,
          enabled: isEnabled,
          style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurface),
          decoration: InputDecoration(
            hintText: 'Ejemplo: Las hojas presentan manchas cafés desde hace tres días.',
            hintStyle: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
            filled: true,
            fillColor: AppColors.aSurfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.aOutlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.aOutlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.aSecondary, width: 2),
            ),
            counterStyle: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 14, color: AppColors.aOnSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Entre más detalles proporciones, más preciso podrá ser el diagnóstico.',
                style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
