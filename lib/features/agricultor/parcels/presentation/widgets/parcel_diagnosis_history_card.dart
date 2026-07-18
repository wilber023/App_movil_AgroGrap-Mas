import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';
import 'parcel_detail_helpers.dart';

/// Tarjeta de un diagnóstico en la pestaña "Historial" de
/// [ParcelDetailPage]: miniatura, enfermedad, cultivo, confianza y estado.
class ParcelDiagnosisHistoryCard extends StatelessWidget {
  final DiagnosisEntity diagnosis;
  final VoidCallback onTap;

  const ParcelDiagnosisHistoryCard({super.key, required this.diagnosis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final confidencePct = (diagnosis.confidence * 100).toStringAsFixed(1);
    final confidenceColor = diagnosis.confidence >= 0.80
        ? AppColors.forestGreen
        : diagnosis.confidence >= 0.60
        ? AppColors.parcelsChipFollowText
        : AppColors.parcelsChipAlertText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.onPrimary,
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: Border.all(
            color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Miniatura de la imagen analizada
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lgXl),
                bottomLeft: Radius.circular(AppRadius.lgXl),
              ),
              child: SizedBox(
                width: 84,
                height: 96,
                child:
                    diagnosis.imagePath != null &&
                        File(diagnosis.imagePath!).existsSync()
                    ? Image.file(File(diagnosis.imagePath!), fit: BoxFit.cover)
                    : Container(
                        color: AppColors.parcelsChipGreenBg,
                        child: const Icon(
                          Icons.eco_outlined,
                          color: AppColors.forestGreen,
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            // Información
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diagnosis.diseaseName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.parcelsTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxsPlus),
                    Text(
                      diagnosis.cropName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.parcelsTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.smMd),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _miniChip(
                          '$confidencePct%',
                          confidenceColor.withValues(alpha: 0.12),
                          confidenceColor,
                        ),
                        _miniChip(
                          diagnosis.statusLabel,
                          diagnosisStatusBg(diagnosis.statusLabel),
                          diagnosisStatusTextColor(diagnosis.statusLabel),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xsPlus),
                    Text(
                      parcelDetailFormatDate(diagnosis.diagnosedAt),
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.parcelsBorderLight),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Icon(
                Icons.chevron_right_outlined,
                color: AppColors.parcelsBorderLight,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.smMd),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
