import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Tarjeta compacta con consejos para tomar una buena foto, mostrada antes
/// del area de captura. Enfoque educativo: ayuda al aprendiz a entender qué
/// hace que una foto sea util para el diagnostico, no solo a tomarla.
class DiagnosisTipsCard extends StatelessWidget {
  const DiagnosisTipsCard({super.key});

  static const _tips = [
    'Usa buena iluminación.',
    'Enfoca únicamente la parte afectada.',
    'Evita fondos con muchas plantas.',
    'Acércate para que se aprecien bien los detalles.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined, color: AppColors.aSecondary, size: 18),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Consejos para una mejor foto',
                style: AppTypography.etiquetaBold.copyWith(color: AppColors.aOnSurface),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ..._tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 14, color: AppColors.aSecondary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      tip,
                      style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
