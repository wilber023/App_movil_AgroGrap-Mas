import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../agricultor/diagnosis/domain/entities/diagnosis_entity.dart';
import '../../../../agricultor/diagnosis/presentation/bloc/llm_diagnosis_cubit.dart';
import '../../../agenda/agenda.dart';
import '../../../cultivo/domain/entities/crop_activity_entity.dart';
import '../../../shell/aprendiz_main_shell.dart';
import '../bloc/diagnosis_result_aprendiz_cubit.dart';
import '../mappers/diagnosis_result_mapper.dart';
import '../models/diagnosis_result_view_data.dart';
import '../widgets/agenda_updated_modal_sheet.dart';
import '../widgets/diagnosis_explanation_card.dart';
import '../widgets/diagnosis_healthy_result_card.dart';
import '../widgets/diagnosis_important_note_card.dart';
import '../widgets/diagnosis_llm_status_card.dart';
import '../widgets/diagnosis_loaded_sections.dart';
import '../widgets/diagnosis_result_bottom_bar.dart';
import '../widgets/diagnosis_result_diagnosis_card.dart';
import '../widgets/diagnosis_result_photo_card.dart';
import '../widgets/diagnosis_result_plant_card.dart';
import '../widgets/diagnosis_result_top_bar.dart';
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
              const DiagnosisResultTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxlPlus,
                    AppSpacing.huge,
                    AppSpacing.xxlPlus,
                    AppSpacing.xhuge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DiagnosisResultPhotoCard(imagePath: _viewData.imagePath),
                      const SizedBox(height: AppSpacing.xxlPlus),
                      DiagnosisResultPlantCard(data: _viewData),
                      const SizedBox(height: AppSpacing.xxlPlus),
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
      const SizedBox(height: AppSpacing.xxlPlus),
      BlocBuilder<LlmDiagnosisCubit, LlmDiagnosisState>(
        builder: (context, state) {
          if (state is LlmDiagnosisLoaded && state.response.diagnostico.trim().isNotEmpty) {
            return DiagnosisExplanationCard(explanation: state.response.diagnostico.trim());
          }
          return const SizedBox.shrink();
        },
      ),
      const SizedBox(height: AppSpacing.xhuge),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.aOrange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
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
      const SizedBox(height: AppSpacing.xxlPlus),
      BlocBuilder<LlmDiagnosisCubit, LlmDiagnosisState>(
        builder: (context, state) {
          if (state is LlmDiagnosisIdle || state is LlmDiagnosisLoading) {
            return const DiagnosisLlmLoadingCard();
          }
          if (state is LlmDiagnosisError) {
            return DiagnosisLlmErrorCard(onRetry: () => context.read<LlmDiagnosisCubit>().consultar(diagnosis: diagnosis, rol: 'aprendiz'));
          }
          if (state is LlmDiagnosisLoaded) {
            return DiagnosisLoadedSections(
              llmData: DiagnosisResultMapper.mapLlmResponse(state.response),
              onViewTreatment: () => _openRecommendedAction(context),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      const SizedBox(height: AppSpacing.xxlPlus),
      const DiagnosisImportantNoteCard(),
      const SizedBox(height: AppSpacing.huge),
      BlocBuilder<DiagnosisResultAprendizCubit, DiagnosisResultAprendizState>(
        builder: (context, state) {
          return DiagnosisResultBottomBar(
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
      backgroundColor: AppColors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => AgendaUpdatedModalSheet(
        activities: activities,
        onViewAgenda: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AprendizMainShell(initialIndex: 3)),
            (route) => false,
          );
        },
      ),
    );
  }
}
