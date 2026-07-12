import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../agricultor/diagnosis/domain/entities/diagnosis_entity.dart';
import '../../../../agricultor/diagnosis/presentation/bloc/llm_diagnosis_cubit.dart';
import '../../../agenda/agenda.dart';
import '../../../cultivo/domain/entities/crop_activity_entity.dart';
import '../../../shell/aprendiz_main_shell.dart';
import '../bloc/diagnosis_result_aprendiz_cubit.dart';
import '../mappers/diagnosis_result_mapper.dart';
import '../models/diagnosis_result_view_data.dart';
import '../widgets/diagnosis_checklist_card.dart';
import '../widgets/diagnosis_evidence_card.dart';
import '../widgets/diagnosis_explanation_card.dart';
import '../widgets/diagnosis_fun_fact_card.dart';
import '../widgets/diagnosis_healthy_result_card.dart';
import '../widgets/diagnosis_important_note_card.dart';
import '../widgets/diagnosis_llm_status_card.dart';
import '../widgets/diagnosis_next_step_card.dart';
import '../widgets/diagnosis_result_bottom_bar.dart';
import '../widgets/diagnosis_result_diagnosis_card.dart';
import '../widgets/diagnosis_result_photo_card.dart';
import '../widgets/diagnosis_result_plant_card.dart';
import '../widgets/diagnosis_risk_card.dart';
import 'aprendiz_recommended_action_page.dart';

class DiagnosisResultAprendizPage extends StatelessWidget {
  final DiagnosisEntity diagnosis;
  final String activityId;

  const DiagnosisResultAprendizPage({
    super.key,
    required this.diagnosis,
    required this.activityId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<DiagnosisResultAprendizCubit>()),
        BlocProvider(
          create: (_) {
            final cubit = sl<LlmDiagnosisCubit>();
            if (diagnosis.llmResponse != null) {
              cubit.loadCached(diagnosis.llmResponse!);
            }
            return cubit;
          },
        ),
      ],
      child: _DiagnosisResultAprendizView(diagnosis: diagnosis, activityId: activityId),
    );
  }
}

class _DiagnosisResultAprendizView extends StatefulWidget {
  final DiagnosisEntity diagnosis;
  final String activityId;

  const _DiagnosisResultAprendizView({
    required this.diagnosis,
    required this.activityId,
  });

  @override
  State<_DiagnosisResultAprendizView> createState() => _DiagnosisResultAprendizViewState();
}

class _DiagnosisResultAprendizViewState extends State<_DiagnosisResultAprendizView> {
  DiagnosisEntity get diagnosis => widget.diagnosis;
  String get activityId => widget.activityId;

  late final DiagnosisResultViewData _viewData = DiagnosisResultMapper.mapResult(diagnosis);

  @override
  void initState() {
    super.initState();
    if (diagnosis.llmResponse == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<LlmDiagnosisCubit>().consultar(diagnosis: diagnosis, rol: 'aprendiz');
      });
    }
  }

  void _saveDiagnosis(BuildContext context) {
    // El diagnostico ya se persiste automaticamente al analizarlo
    // (AprendizDiagnosisRepositoryImpl.analyzeCrop -> insertDiagnosis), asi
    // que este boton solo confirma el estado real, sin logica nueva.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Diagnóstico guardado en tu historial', style: AppTypography.agendaBody.copyWith(color: AppColors.aOnPrimary)),
        backgroundColor: AppColors.aSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _scheduleFollowUp(BuildContext context) {
    if (activityId.isNotEmpty) {
      context.read<DiagnosisResultAprendizCubit>().acceptAction(activityId);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AprendizAgendaPage()));
    }
  }

  void _openRecommendedAction(BuildContext context) {
    final llmState = context.read<LlmDiagnosisCubit>().state;
    final llmResponse = llmState is LlmDiagnosisLoaded ? llmState.response : null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AprendizRecommendedActionPage(
          diseaseName: diagnosis.diseaseName,
          cropName: diagnosis.cropName,
          llmResponse: llmResponse,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DiagnosisResultAprendizCubit, DiagnosisResultAprendizState>(
          listener: (context, state) {
            if (state is AgendaUpdated) {
              _showAgendaUpdatedModal(context, state.newActivities);
            } else if (state is DiagnosisResultError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message, style: AppTypography.agendaBody.copyWith(color: AppColors.aOnPrimary)),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
        BlocListener<LlmDiagnosisCubit, LlmDiagnosisState>(
          listener: (context, state) {
            if (state is LlmDiagnosisLoaded && diagnosis.llmResponse == null) {
              context.read<DiagnosisResultAprendizCubit>().saveLlmResponse(
                    diagnosisId: diagnosis.id,
                    llmResponse: state.response,
                  );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.aMint,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DiagnosisResultPhotoCard(imagePath: _viewData.imagePath),
                      const SizedBox(height: 16),
                      DiagnosisResultPlantCard(data: _viewData),
                      const SizedBox(height: 16),
                      if (_viewData.isHealthy)
                        ..._buildHealthyContent(context)
                      else
                        ..._buildDiseaseContent(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHealthyContent(BuildContext context) {
    return [
      const DiagnosisHealthyResultCard(),
      const SizedBox(height: 16),
      BlocBuilder<LlmDiagnosisCubit, LlmDiagnosisState>(
        builder: (context, state) {
          if (state is LlmDiagnosisLoaded && state.response.diagnostico.trim().isNotEmpty) {
            return DiagnosisExplanationCard(explanation: state.response.diagnostico.trim());
          }
          return const SizedBox.shrink();
        },
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.aOrange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text(
            'Continuar',
            style: AppTypography.agendaTitle.copyWith(fontSize: 16, color: AppColors.aOnPrimary),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildDiseaseContent(BuildContext context) {
    return [
      DiagnosisResultDiagnosisCard(data: _viewData),
      const SizedBox(height: 16),
      BlocBuilder<LlmDiagnosisCubit, LlmDiagnosisState>(
        builder: (context, state) {
          if (state is LlmDiagnosisIdle || state is LlmDiagnosisLoading) {
            return const DiagnosisLlmLoadingCard();
          }
          if (state is LlmDiagnosisError) {
            return DiagnosisLlmErrorCard(onRetry: () => context.read<LlmDiagnosisCubit>().consultar(diagnosis: diagnosis, rol: 'aprendiz'));
          }
          if (state is LlmDiagnosisLoaded) {
            return _LoadedDiagnosisSections(
              llmData: DiagnosisResultMapper.mapLlmResponse(state.response),
              onViewTreatment: () => _openRecommendedAction(context),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      const SizedBox(height: 16),
      const DiagnosisImportantNoteCard(),
      const SizedBox(height: 20),
      BlocBuilder<DiagnosisResultAprendizCubit, DiagnosisResultAprendizState>(
        builder: (context, state) {
          return DiagnosisResultBottomBar(
            onSave: () => _saveDiagnosis(context),
            onScheduleFollowUp: () => _scheduleFollowUp(context),
            isSchedulingFollowUp: state is DiagnosisResultLoading,
          );
        },
      ),
    ];
  }

  void _showAgendaUpdatedModal(BuildContext context, List<CropActivityEntity> activities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.aSurfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.aOutlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.aSecondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, size: 36, color: AppColors.aSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                '¡Agenda actualizada!',
                style: AppTypography.agendaTitle.copyWith(color: AppColors.aOnSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Se crearon ${activities.length} actividades en tu agenda:',
                style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ...activities.take(3).map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.aOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          a.title,
                          style: AppTypography.agendaBody.copyWith(fontWeight: FontWeight.w500, color: AppColors.aOnSurface),
                        ),
                      ),
                      Text(
                        '${a.scheduledDate.day}/${a.scheduledDate.month}',
                        style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AprendizMainShell(initialIndex: 3)),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.aOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Ver mi agenda',
                    style: AppTypography.agendaTitle.copyWith(fontSize: 16, color: AppColors.aOnPrimary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.aPrimaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.aOnPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Resultado de tu análisis',
              textAlign: TextAlign.center,
              style: AppTypography.agendaTitle.copyWith(fontSize: 17, color: AppColors.aOnPrimary),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Compone las tarjetas que dependen de la respuesta del LLM ya cargada:
/// qué está pasando + evidencia, acciones + prevención, y la fila de
/// dato curioso / riesgos / próximo paso — cada fila con tarjetas de igual
/// altura y solo mostrando las que realmente tienen contenido.
class _LoadedDiagnosisSections extends StatelessWidget {
  final DiagnosisLlmViewData llmData;
  final VoidCallback onViewTreatment;

  const _LoadedDiagnosisSections({required this.llmData, required this.onViewTreatment});

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
        if (topRow.isNotEmpty) const SizedBox(height: 16),
        if (actionsRow.isNotEmpty) _EqualHeightRow(children: actionsRow),
        if (actionsRow.isNotEmpty) const SizedBox(height: 16),
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
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}
