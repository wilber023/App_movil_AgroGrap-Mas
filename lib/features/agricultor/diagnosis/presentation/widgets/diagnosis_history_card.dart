import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/diagnosis_entity.dart';
import '../pages/diagnosis_result_page.dart';

/// Tarjeta de un diagnóstico en el historial (usada tanto por
/// [DiagnosisHistorySheet] como por [DiagnosisHistoryFullPage]).
class DiagnosisHistoryCard extends StatelessWidget {
  const DiagnosisHistoryCard({super.key, required this.diagnosis});

  final DiagnosisEntity diagnosis;

  @override
  Widget build(BuildContext context) {
    final e = diagnosis;
    Color statusBg = AppColors.parcelsChipGreenBg;
    Color statusText = AppColors.parcelsChipGreenText;
    if (e.statusLabel == 'En tratamiento' || e.statusLabel == 'Seguimiento') {
      statusBg = AppColors.parcelsChipFollowBg;
      statusText = AppColors.parcelsChipFollowText;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DiagnosisResultPage(diagnosis: e)),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.none, AppSpacing.xl, AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.onPrimary,
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: Border.all(
            color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.diagnosisThumbBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: e.imagePath != null
                  ? const Icon(Icons.image, size: 24, color: AppColors.parcelsTextSecondary)
                  : const Icon(
                      Icons.eco_outlined,
                      size: 24,
                      color: AppColors.parcelsTextSecondary,
                    ),
            ),
            const SizedBox(width: AppSpacing.xl),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: name + severity dot
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.diseaseName,
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.parcelsTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.forestGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxsPlus),
                  // Row 2: crop chip
                  Row(
                    children: [
                      _buildPill(e.cropName, AppColors.parcelsChipGreenBg, AppColors.parcelsChipGreenText),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Row 3: date + status chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${e.diagnosedAt.day}/${e.diagnosedAt.month}/${e.diagnosedAt.year}',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.parcelsBorderLight),
                      ),
                      _buildPill(e.statusLabel, statusBg, statusText),
                    ],
                  ),
                  // Row 4: treatment bar
                  if (e.treatmentProgress != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                            child: SizedBox(
                              height: 4,
                              child: LinearProgressIndicator(
                                value: e.treatmentProgress!,
                                backgroundColor: AppColors.parcelsTrackGrey,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.forestGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (e.treatmentStep != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            e.treatmentStep!,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppColors.parcelsTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: text,
        ),
      ),
    );
  }
}
