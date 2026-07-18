import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/diagnosis_entity.dart';

/// SliverAppBar con la imagen del diagnóstico, badge de "completado",
/// nombre de la enfermedad y chips de cultivo/confianza. Cabecera de
/// [DiagnosisResultPage].
class DiagnosisHeroSliver extends StatelessWidget {
  const DiagnosisHeroSliver({super.key, required this.diagnosis});

  final DiagnosisEntity diagnosis;

  @override
  Widget build(BuildContext context) {
    final imagePath = diagnosis.imagePath;
    final hasImage = imagePath != null && File(imagePath).existsSync();

    return SliverAppBar(
      expandedHeight: 290,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.diagnosisCameraGradientStart,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        diagnosis.diseaseName,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo
            hasImage
                ? Image.file(File(imagePath), fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.diagnosisCameraGradientStart, AppColors.diagnosisHeroGradientEnd],
                      ),
                    ),
                  ),
            // Gradiente oscuro para legibilidad
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.diagnosisHeroOverlayStart, AppColors.diagnosisHeroOverlayEnd],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
            // Contenido sobre la imagen
            Positioned(
              bottom: AppSpacing.none,
              left: AppSpacing.none,
              right: AppSpacing.none,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.none, AppSpacing.xxlPlus, AppSpacing.hugePlus),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge "Diagnóstico completado"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.diagnosisCompletedBadge.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 12,
                            color: AppColors.onPrimary,
                          ),
                          SizedBox(width: AppSpacing.xsPlus),
                          Text(
                            'Diagnóstico completado',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Nombre de la enfermedad
                    Text(
                      diagnosis.diseaseName,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Chips de cultivo + confianza
                    Row(
                      children: [
                        _heroChip('🌱 ${diagnosis.cropName}'),
                        const SizedBox(width: AppSpacing.md),
                        _heroChip(
                          'Alta confianza '
                          '${(diagnosis.confidence * 100).toInt()}%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
    decoration: BoxDecoration(
      color: AppColors.onPrimary.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
      border: Border.all(
        color: AppColors.onPrimary.withValues(alpha: 0.28),
        width: 0.5,
      ),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(fontSize: 11, color: AppColors.onPrimary),
    ),
  );
}
