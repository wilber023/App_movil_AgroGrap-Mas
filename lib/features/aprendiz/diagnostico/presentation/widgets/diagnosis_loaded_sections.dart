import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../models/diagnosis_result_view_data.dart';
import 'diagnosis_detail_blocks.dart';
import 'diagnosis_section_carousel.dart';
import 'diagnosis_section_item.dart';

/// Compone el carrusel de secciones del diagnóstico ya cargado por el LLM:
/// qué está pasando, qué hacer, cómo prevenir, un dato curioso, riesgos y
/// el próximo paso. Cada sección aparece primero como una tarjeta resumen
/// y se expande a una experiencia inmersiva al tocarla, en vez de mostrar
/// todo el texto de golpe.
class DiagnosisLoadedSections extends StatelessWidget {
  final DiagnosisLlmViewData llmData;
  final VoidCallback onViewTreatment;

  const DiagnosisLoadedSections({super.key, required this.llmData, required this.onViewTreatment});

  @override
  Widget build(BuildContext context) {
    final actionsCount = llmData.actions.length;
    final preventionCount = llmData.prevention.length;
    final risksCount = llmData.risks.length;

    final items = <DiagnosisSectionItem>[
      if (llmData.whatIsHappening.isNotEmpty)
        DiagnosisSectionItem(
          id: 'explanation',
          icon: Icons.menu_book_outlined,
          accent: AppColors.aSecondary,
          background: AppColors.aMint,
          border: AppColors.aSecondaryContainer,
          title: '¿Qué está pasando?',
          summary: 'Entiende, en palabras simples, qué le ocurre a tu cultivo.',
          expandedBuilder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DiagnosisDetailParagraph(llmData.whatIsHappening),
              if (llmData.evidence.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxhuge),
                const DiagnosisDetailSectionLabel('CÓMO LO DETECTAMOS'),
                DiagnosisDetailStepList(items: llmData.evidence, accent: AppColors.aSecondary),
              ],
            ],
          ),
        ),
      if (actionsCount > 0)
        DiagnosisSectionItem(
          id: 'actions',
          icon: Icons.assignment_outlined,
          accent: AppColors.aOrange,
          background: AppColors.aWarningBg,
          border: AppColors.aWarningBorder,
          title: '¿Qué puedes hacer ahora?',
          summary: actionsCount == 1 ? '1 acción recomendada para tu cultivo.' : '$actionsCount acciones recomendadas para tu cultivo.',
          expandedBuilder: (context) => DiagnosisDetailStepList(items: llmData.actions, accent: AppColors.aOrange),
        ),
      if (preventionCount > 0)
        DiagnosisSectionItem(
          id: 'prevention',
          icon: Icons.shield_outlined,
          accent: AppColors.aSecondary,
          background: AppColors.aSecondaryContainer,
          border: AppColors.aSecondary,
          title: '¿Cómo prevenirlo?',
          summary: preventionCount == 1 ? '1 recomendación disponible.' : '$preventionCount recomendaciones disponibles.',
          expandedBuilder: (context) => DiagnosisDetailStepList(items: llmData.prevention, accent: AppColors.aSecondary),
        ),
      if (llmData.funFact != null)
        DiagnosisSectionItem(
          id: 'fun-fact',
          icon: Icons.school_outlined,
          accent: AppColors.aOnTertiaryFixedVariant,
          background: AppColors.aTertiaryFixed,
          border: AppColors.aOnTertiaryFixedVariant,
          title: 'Aprende algo nuevo',
          summary: 'Un dato curioso sobre tu cultivo te espera.',
          expandedBuilder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DiagnosisDetailSectionLabel('¿SABÍAS QUE...?', color: AppColors.aOnTertiaryFixedVariant),
              DiagnosisDetailParagraph(llmData.funFact!),
            ],
          ),
        ),
      if (risksCount > 0)
        DiagnosisSectionItem(
          id: 'risks',
          icon: Icons.error_outline,
          accent: AppColors.aWarningText,
          background: AppColors.aWarningBg,
          border: AppColors.aWarningBorder,
          title: 'Riesgos si no actúas',
          summary: risksCount == 1 ? '1 riesgo identificado.' : '$risksCount riesgos identificados.',
          expandedBuilder: (context) => DiagnosisDetailStepList(items: llmData.risks, accent: AppColors.aWarningText),
        ),
      DiagnosisSectionItem(
        id: 'next-step',
        icon: Icons.arrow_circle_right_outlined,
        accent: AppColors.infoBlue,
        background: AppColors.infoBlue.withValues(alpha: 0.10),
        border: AppColors.infoBlue.withValues(alpha: 0.35),
        title: 'Próximo paso',
        summary: 'Revisa el tratamiento recomendado para tu cultivo.',
        expandedBuilder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DiagnosisDetailParagraph(
              'Te recomendamos revisar el tratamiento recomendado para controlar el problema en tu cultivo.',
            ),
            const SizedBox(height: AppSpacing.xxhuge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onViewTreatment();
                },
                icon: const Icon(Icons.medical_services_outlined, size: 18, color: AppColors.aOnPrimary),
                label: Text(
                  'Ver tratamiento',
                  style: AppTypography.labelMd.copyWith(color: AppColors.aOnPrimary, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.infoBlue,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    ];

    return DiagnosisSectionCarousel(items: items);
  }
}
