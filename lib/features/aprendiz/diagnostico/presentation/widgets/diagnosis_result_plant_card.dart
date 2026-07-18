import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../models/diagnosis_result_view_data.dart';
import 'diagnosis_confidence_ring.dart';
import 'diagnosis_result_card.dart';

/// Tarjeta "Planta identificada": nombre + familia botanica (izquierda) y
/// anillo de confianza del reconocimiento (derecha), con una breve
/// descripcion segun el nivel de confianza.
class DiagnosisResultPlantCard extends StatelessWidget {
  final DiagnosisResultViewData data;

  const DiagnosisResultPlantCard({super.key, required this.data});

  String get _confidenceDescription => switch (data.confidenceLevel) {
        ConfidenceLevel.high => 'La planta coincide con características típicas.',
        ConfidenceLevel.medium => 'La planta coincide parcialmente con las características esperadas.',
        ConfidenceLevel.low => 'La coincidencia es baja: intenta con una foto más clara.',
      };

  @override
  Widget build(BuildContext context) {
    return DiagnosisResultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.aMint, shape: BoxShape.circle),
                child: const Icon(Icons.eco_outlined, color: AppColors.aSecondary, size: 24),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLANTA IDENTIFICADA',
                      style: AppTypography.statusPill.copyWith(color: AppColors.aOnSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      data.cropName,
                      style: AppTypography.agendaTitle.copyWith(fontSize: 17, color: AppColors.aOnSurface),
                    ),
                    if (data.cropFamily != null)
                      Text(
                        data.cropFamily!,
                        style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    'Confianza del\nreconocimiento',
                    textAlign: TextAlign.center,
                    style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DiagnosisConfidenceRing(confidence: data.confidence, level: data.confidenceLevel),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _confidenceDescription,
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
