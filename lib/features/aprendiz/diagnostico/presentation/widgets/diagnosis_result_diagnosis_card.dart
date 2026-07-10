import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../models/diagnosis_result_view_data.dart';
import 'diagnosis_result_card.dart';
import 'diagnosis_severity_badge.dart';

/// Tarjeta "Diagnóstico": enfermedad + tipo (izquierda) y severidad
/// (derecha), con una breve descripcion segun el nivel de severidad.
class DiagnosisResultDiagnosisCard extends StatelessWidget {
  final DiagnosisResultViewData data;

  const DiagnosisResultDiagnosisCard({super.key, required this.data});

  String get _typeLabel => switch (data.diagnosisType) {
        DiagnosisType.fungus => 'Hongo',
        DiagnosisType.bacteria => 'Bacteria',
        DiagnosisType.pest => 'Plaga',
        DiagnosisType.virus => 'Virus',
        DiagnosisType.unknown => 'Enfermedad',
      };

  String get _severityDescription => switch (data.severity) {
        SeverityLevel.low => 'Sin urgencia: sigue el seguimiento habitual.',
        SeverityLevel.moderate => 'Requiere atención pronta.',
        SeverityLevel.high => 'Requiere atención inmediata.',
      };

  @override
  Widget build(BuildContext context) {
    return DiagnosisResultCard(
      color: AppColors.aDiseaseCardBg,
      borderColor: AppColors.aDiseaseCardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.aOnPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.search_rounded, color: AppColors.error, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIAGNÓSTICO',
                      style: AppTypography.statusPill.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.diseaseName,
                      style: AppTypography.agendaTitle.copyWith(fontSize: 17, color: AppColors.aDiseaseCardText),
                    ),
                    Text(
                      _typeLabel,
                      style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Severidad',
                    style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  DiagnosisSeverityBadge(severity: data.severity),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _severityDescription,
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
