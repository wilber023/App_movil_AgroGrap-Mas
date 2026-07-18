import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Seccion educativa "Lo que aprenderás", preparada para mostrar el
/// contenido de un resultado real una vez exista integracion con el
/// diagnostico por IA. Mientras no se le pase ningun dato permanece oculta
/// (`SizedBox.shrink()`), por lo que hoy no se renderiza nada — solo queda
/// la estructura lista para conectarse.
class DiagnosisLearningSection extends StatelessWidget {
  final String? possibleDisease;
  final String? cause;
  final String? prevention;
  final String? recommendedCare;

  const DiagnosisLearningSection({
    super.key,
    this.possibleDisease,
    this.cause,
    this.prevention,
    this.recommendedCare,
  });

  bool get _hasContent =>
      possibleDisease != null || cause != null || prevention != null || recommendedCare != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasContent) return const SizedBox.shrink();

    final rows = [
      ('Posible enfermedad', possibleDisease, Icons.search_rounded),
      ('Qué la provoca', cause, Icons.science_outlined),
      ('Cómo prevenirla', prevention, Icons.shield_outlined),
      ('Cuidados recomendados', recommendedCare, Icons.eco_outlined),
    ].where((r) => r.$2 != null);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_outlined, size: 18, color: AppColors.aSecondary),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Lo que aprenderás',
                style: AppTypography.agendaSectionTitle.copyWith(color: AppColors.aOnSurface),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(r.$3, size: 16, color: AppColors.aOnSurfaceVariant),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.$1,
                          style: AppTypography.etiquetaBold.copyWith(color: AppColors.aOnSurface),
                        ),
                        Text(
                          r.$2!,
                          style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                        ),
                      ],
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
