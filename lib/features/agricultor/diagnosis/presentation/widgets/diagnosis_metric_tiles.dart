import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Fila de tiles "Riesgo actual / Gravedad / Confianza IA" mostrada dentro
/// de [DiagnosisSummaryCard].
class DiagnosisMetricTiles extends StatelessWidget {
  const DiagnosisMetricTiles({
    super.key,
    required this.confidence,
    required this.isHealthy,
  });

  final double confidence;
  final bool isHealthy;

  @override
  Widget build(BuildContext context) {
    final conf = confidence;
    final String riskLabel;
    final Color riskColor;
    final String gravLabel;
    final Color gravColor;

    if (isHealthy) {
      riskLabel = 'Bajo';
      riskColor = AppColors.diagnosisRiskLow;
      gravLabel = 'Leve';
      gravColor = AppColors.diagnosisRiskLow;
    } else if (conf >= 0.85) {
      riskLabel = 'Alto';
      riskColor = AppColors.diagnosisRiskHigh;
      gravLabel = 'Severa';
      gravColor = AppColors.diagnosisRiskHigh;
    } else if (conf >= 0.65) {
      riskLabel = 'Moderado';
      riskColor = AppColors.diagnosisRiskMed;
      gravLabel = 'Moderada';
      gravColor = AppColors.forestGreen;
    } else {
      riskLabel = 'Bajo';
      riskColor = AppColors.diagnosisRiskLow;
      gravLabel = 'Leve';
      gravColor = AppColors.diagnosisRiskLow;
    }

    // Row simple (sin IntrinsicHeight/stretch): cada tarjeta crece segun su
    // propio contenido. Con IntrinsicHeight, cuando el valor ("Moderado")
    // envolvia a 2 lineas, el calculo de alto intrinseco no siempre
    // coincidia exactamente con el alto real ya renderizado, y esa
    // diferencia de unos pocos pixeles causaba el desborde. Sin forzar una
    // altura comun entre las 3 tarjetas, no hay nada que desbordar.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _metricTile(
            icon: Icons.local_fire_department_outlined,
            iconColor: riskColor,
            value: riskLabel,
            valueColor: riskColor,
            label: 'Riesgo actual',
            sub: isHealthy ? 'Sin enfermedad' : 'Condiciones favorables',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _metricTile(
            icon: Icons.waves_outlined,
            iconColor: gravColor,
            value: gravLabel,
            valueColor: gravColor,
            label: 'Gravedad',
            sub: 'Manchas visibles\nen hojas',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _metricTile(
            icon: Icons.diamond_outlined,
            iconColor: AppColors.diagnosisMetricBlue,
            value: '${(conf * 100).toInt()}%',
            valueColor: AppColors.diagnosisMetricBlue,
            label: 'Confianza IA',
            sub: 'Análisis basado\nen modelo',
          ),
        ),
      ],
    );
  }

  Widget _metricTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required Color valueColor,
    required String label,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        border: Border.all(color: AppColors.parcelsTrackGrey, width: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.lgXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.parcelsTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 8,
              color: AppColors.parcelsTextSecondary.withValues(alpha: 0.75),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
