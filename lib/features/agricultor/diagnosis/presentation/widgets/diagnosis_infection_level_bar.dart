import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/diagnosis_entity.dart';

/// Tarjeta con la barra de gradiente "Nivel de infección detectado" de
/// [DiagnosisResultPage], con marcador de posición y etiquetas de severidad.
class DiagnosisInfectionLevelBar extends StatelessWidget {
  const DiagnosisInfectionLevelBar({super.key, required this.diagnosis});

  final DiagnosisEntity diagnosis;

  @override
  Widget build(BuildContext context) {
    final isHealthy = diagnosis.statusLabel == 'Saludable';
    final position = isHealthy
        ? 0.06
        : diagnosis.confidence.clamp(0.0, 1.0);

    const labels = ['Leve', 'Moderado', 'Severo', 'Crítico'];
    final int activeIdx = position < 0.28
        ? 0
        : position < 0.58
        ? 1
        : position < 0.83
        ? 2
        : 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(color: AppColors.parcelsTrackGrey, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nivel de infección detectado',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.parcelsTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final markerLeft = (w * position).clamp(6.0, w - 14.0) - 10;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Barra gradiente
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.diagnosisInfectionGreen,
                          AppColors.diagnosisInfectionYellow,
                          AppColors.diagnosisInfectionOrange,
                          AppColors.diagnosisRiskHigh,
                        ],
                      ),
                    ),
                  ),
                  // Marcador
                  Positioned(
                    left: markerLeft,
                    top: -6,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.onPrimary,
                        border: Border.all(
                          color: AppColors.diagnosisRiskMed,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          // Etiquetas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(labels.length, (i) {
              final isActive = i == activeIdx;
              return Text(
                labels[i],
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive
                      ? AppColors.diagnosisRiskHigh
                      : AppColors.parcelsTextSecondary.withValues(alpha: 0.65),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
