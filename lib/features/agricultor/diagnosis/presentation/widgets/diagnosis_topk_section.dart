import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/services/cnn_engine/cnn_result.dart';

/// Desplegable "Otras predicciones del modelo" (Top-K) mostrado dentro de
/// [DiagnosisSummaryCard] cuando hay más de una predicción.
class DiagnosisTopKSection extends StatelessWidget {
  const DiagnosisTopKSection({super.key, required this.topK});

  final List<TopKPrediction> topK;

  @override
  Widget build(BuildContext context) {
    final others = topK.skip(1).toList();
    if (others.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.none),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.none, AppSpacing.xxlPlus, AppSpacing.xl),
        title: Text(
          'Otras predicciones del modelo (${others.length})',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.parcelsTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: AppColors.parcelsTextSecondary,
        collapsedIconColor: AppColors.parcelsTextSecondary,
        children: others.map(_buildTopKRow).toList(),
      ),
    );
  }

  Widget _buildTopKRow(TopKPrediction p) {
    final pct = (p.confidence * 100).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${p.cropName} · ${p.diseaseName}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.parcelsTextPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.parcelsTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxsPlus),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: p.confidence.clamp(0.0, 1.0),
                backgroundColor: AppColors.parcelsTrackGrey,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.parcelsTextSecondary.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
