import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Card base reutilizada por toda la pantalla de Resultado: mismo radio,
/// borde y sombra sutil para que todas las secciones se sientan parte de
/// un mismo sistema visual.
class DiagnosisResultCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  const DiagnosisResultCard({
    super.key,
    required this.child,
    this.color = AppColors.aSurfaceContainerLowest,
    this.borderColor = AppColors.aOutlineVariant,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: AppColors.aOnSurface.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}
