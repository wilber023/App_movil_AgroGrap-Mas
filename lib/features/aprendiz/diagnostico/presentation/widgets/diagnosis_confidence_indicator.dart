import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Nivel de confianza que el motor de diagnostico asigna a un resultado.
enum DiagnosisConfidenceLevel { high, medium, low }

/// Indicador de confianza del diagnostico, preparado para el resultado real
/// una vez exista la integracion con el motor de IA. Sin `level`/`percentage`
/// permanece oculto (`SizedBox.shrink()`) — hoy no se renderiza nada, solo
/// queda la estructura lista para conectarse (ver punto 5 del pedido:
/// "no implementes la lógica; solo prepara la estructura").
class DiagnosisConfidenceIndicator extends StatelessWidget {
  final DiagnosisConfidenceLevel? level;
  final int? percentage;

  const DiagnosisConfidenceIndicator({super.key, this.level, this.percentage});

  @override
  Widget build(BuildContext context) {
    final level = this.level;
    final percentage = this.percentage;
    if (level == null || percentage == null) return const SizedBox.shrink();

    final (label, color) = switch (level) {
      DiagnosisConfidenceLevel.high => ('Alta', AppColors.aSecondary),
      DiagnosisConfidenceLevel.medium => ('Media', AppColors.aOrange),
      DiagnosisConfidenceLevel.low => ('Baja', AppColors.error),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Nivel de confianza',
          style: AppTypography.etiquetaBold.copyWith(color: AppColors.aOnSurface),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Text(label, style: AppTypography.etiquetaSm.copyWith(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text(
              '$percentage%',
              style: AppTypography.etiquetaBold.copyWith(color: AppColors.aOnSurface),
            ),
          ],
        ),
      ],
    );
  }
}
