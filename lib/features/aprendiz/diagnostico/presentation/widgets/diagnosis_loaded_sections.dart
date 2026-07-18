import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../models/diagnosis_result_view_data.dart';
import 'diagnosis_checklist_card.dart';
import 'diagnosis_evidence_card.dart';
import 'diagnosis_explanation_card.dart';
import 'diagnosis_fun_fact_card.dart';
import 'diagnosis_next_step_card.dart';
import 'diagnosis_risk_card.dart';

/// Compone las tarjetas que dependen de la respuesta del LLM ya cargada:
/// qué está pasando + evidencia, acciones + prevención, y la fila de
/// dato curioso / riesgos / próximo paso — cada fila con tarjetas de igual
/// altura y solo mostrando las que realmente tienen contenido.
class DiagnosisLoadedSections extends StatelessWidget {
  final DiagnosisLlmViewData llmData;
  final VoidCallback onViewTreatment;

  const DiagnosisLoadedSections({super.key, required this.llmData, required this.onViewTreatment});

  @override
  Widget build(BuildContext context) {
    final topRow = <Widget>[
      if (llmData.whatIsHappening.isNotEmpty) DiagnosisExplanationCard(explanation: llmData.whatIsHappening),
      if (llmData.evidence.isNotEmpty) DiagnosisEvidenceCard(evidence: llmData.evidence),
    ];

    final actionsRow = <Widget>[
      if (llmData.actions.isNotEmpty)
        DiagnosisChecklistCard(
          icon: Icons.assignment_outlined,
          iconColor: AppColors.aOrange,
          backgroundColor: AppColors.aWarningBg,
          borderColor: AppColors.aWarningBorder,
          title: '¿Qué puedes hacer ahora?',
          items: llmData.actions,
        ),
      if (llmData.prevention.isNotEmpty)
        DiagnosisChecklistCard(
          icon: Icons.shield_outlined,
          iconColor: AppColors.aSecondary,
          backgroundColor: AppColors.aSecondaryContainer,
          borderColor: AppColors.aSecondary,
          title: '¿Cómo prevenirlo?',
          items: llmData.prevention,
        ),
    ];

    final smallCards = <Widget>[
      if (llmData.funFact != null) DiagnosisFunFactCard(funFact: llmData.funFact),
      if (llmData.risks.isNotEmpty) DiagnosisRiskCard(risks: llmData.risks),
      DiagnosisNextStepCard(
        description: 'Te recomendamos revisar el tratamiento recomendado para controlar el problema en tu cultivo.',
        actionLabel: 'Ver tratamiento',
        onAction: onViewTreatment,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topRow.isNotEmpty) _EqualHeightRow(children: topRow),
        if (topRow.isNotEmpty) const SizedBox(height: AppSpacing.xxlPlus),
        if (actionsRow.isNotEmpty) _EqualHeightRow(children: actionsRow),
        if (actionsRow.isNotEmpty) const SizedBox(height: AppSpacing.xxlPlus),
        _EqualHeightRow(children: smallCards),
      ],
    );
  }
}

/// Fila de tarjetas de igual altura (usa la mas alta de las visibles),
/// con espaciado uniforme entre ellas.
class _EqualHeightRow extends StatelessWidget {
  final List<Widget> children;
  const _EqualHeightRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xl),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}
