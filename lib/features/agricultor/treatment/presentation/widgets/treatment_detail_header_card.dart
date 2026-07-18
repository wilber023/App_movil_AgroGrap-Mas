import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/treatment_entity.dart';
import 'treatment_detail_helpers.dart';

/// Encabezado de [TreatmentDetailPage]: icono/color de identidad,
/// enfermedad, cultivo, estado y datos generales (inicio, total de pasos).
class TreatmentDetailHeaderCard extends StatelessWidget {
  final TreatmentEntity treatment;
  const TreatmentDetailHeaderCard({super.key, required this.treatment});

  @override
  Widget build(BuildContext context) {
    final accent = detailAccentColor(treatment);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Icon(
                  detailCardIcon(treatment),
                  color: accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treatment.diseaseName,
                      style: AppTypography.tituloMd.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(Icons.eco_outlined,
                            size: 14, color: AppColors.forestGreen),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            treatment.cropName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.etiquetaSm.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.mdLg),
                ),
                child: Text(
                  detailHeaderStatusLabel(treatment),
                  style: AppTypography.etiquetaSm.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxlPlus),
          const Divider(height: 1, thickness: 0.5, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.xl),
          _InfoRow(label: 'Iniciado', value: detailFmtLong(treatment.createdAt)),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Total de pasos', value: '${treatment.totalSteps}'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        Text(
          value,
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
