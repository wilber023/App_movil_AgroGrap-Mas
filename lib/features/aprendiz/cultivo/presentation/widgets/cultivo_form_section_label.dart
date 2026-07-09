import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Etiqueta de seccion del formulario de registro (texto en negrita, sin
/// numeracion).
class CultivoFormSectionLabel extends StatelessWidget {
  final String label;
  const CultivoFormSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.agendaSubtitle.copyWith(
        color: AppColors.aOnSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
