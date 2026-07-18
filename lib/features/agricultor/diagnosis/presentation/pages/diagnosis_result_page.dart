import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/network_info.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../treatment/domain/usecases/treatment_usecases.dart';
import '../../../../offline_knowledge/domain/cultivo_slug.dart';
import '../../../../offline_knowledge/presentation/cubit/offline_knowledge_cubit.dart';
import '../../domain/entities/diagnosis_entity.dart';
import '../bloc/diagnosis_bloc.dart';
import '../bloc/llm_diagnosis_cubit.dart';
import '../cubit/product_recommendation_cubit.dart';
import '../../../treatment/presentation/bloc/treatment_bloc.dart';
import '../widgets/diagnosis_agenda_button.dart';
import '../widgets/diagnosis_hero_sliver.dart';
import '../widgets/diagnosis_infection_level_bar.dart';
import '../widgets/diagnosis_products_section.dart';
import '../widgets/diagnosis_recommendations_section.dart';
import '../widgets/diagnosis_summary_card.dart';

// =============================================================================
// Punto de entrada: inyecta cubits y pasa a la vista con estado
// =============================================================================

class DiagnosisResultPage extends StatelessWidget {
  final DiagnosisEntity diagnosis;
  final String? userText;

  const DiagnosisResultPage({
    super.key,
    required this.diagnosis,
    this.userText,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = sl<LlmDiagnosisCubit>();
            if (diagnosis.llmResponse != null) {
              cubit.loadCached(diagnosis.llmResponse!);
            }
            return cubit;
          },
        ),
        BlocProvider(create: (_) => sl<ProductRecommendationCubit>()),
        BlocProvider(create: (_) => sl<OfflineKnowledgeCubit>()),
      ],
      child: _ResultView(diagnosis: diagnosis, userText: userText),
    );
  }
}

// =============================================================================
// Vista interna con estado
// =============================================================================

class _ResultView extends StatefulWidget {
  final DiagnosisEntity diagnosis;
  final String? userText;
  const _ResultView({required this.diagnosis, this.userText});

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  late bool _isAddedToAgenda;

  @override
  void initState() {
    super.initState();
    _isAddedToAgenda = sl<IsActivePlanForUseCase>()(widget.diagnosis.id);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (widget.diagnosis.llmResponse == null) {
        // === Punto de integración offline_knowledge ===
        // Único lugar que decide entre el flujo online existente
        // (LlmDiagnosisCubit, sin cambios) y el fallback offline
        // (GetOfflineDiagnosisDetailUseCase vía OfflineKnowledgeCubit).
        // Revertir: eliminar este if/else y dejar solo la rama `consultar`.
        final isOnline = await sl<NetworkInfo>().isConnected;
        if (!mounted) return;
        if (isOnline) {
          context.read<LlmDiagnosisCubit>().consultar(
            diagnosis: widget.diagnosis,
            rol: 'agricultor',
            userText: widget.userText,
          );
        } else {
          context.read<OfflineKnowledgeCubit>().load(
            cultivo: cultivoSlug(widget.diagnosis.cropName),
            enfermedadId: _offlineEnfermedadId(widget.diagnosis),
            confianzaCnn: widget.diagnosis.confidence,
          );
        }
      } else {
        context.read<ProductRecommendationCubit>().getRecommendations(
          disease: widget.diagnosis.diseaseName,
          crop: widget.diagnosis.cropName,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // offline_knowledge — helpers de mapeo hacia el paquete local
  // ---------------------------------------------------------------------------

  /// El `id` de ficha del paquete offline debe coincidir con `disease_name`
  /// del catálogo real (README_ofline.md, GET /api/v1/offline/catalog),
  /// normalizado igual que el flujo online ya envía `resultado_cnn.enfermedad`
  /// a /api/v1/consultar (ver LlmDiagnosisDataSourceImpl). El raw label de
  /// la CNN (`topK.first.rawLabel`) YA NO se usa aquí: es un identificador
  /// interno del modelo (ej. "Calabaza_Powdery Mildew") sin relación con
  /// los `doc_id` opacos del backend, a diferencia de lo asumido en el
  /// documento de especificación original (Sprint 1).
  String _offlineEnfermedadId(DiagnosisEntity diagnosis) =>
      cultivoSlug(diagnosis.diseaseName);

  Future<void> _addToAgenda() async {
    final llmState = context.read<LlmDiagnosisCubit>().state;
    if (llmState is! LlmDiagnosisLoaded) return;
    final r = llmState.response;

    final existingResult = await sl<GetTreatmentAgendaUseCase>()(const NoParams());
    final hasActivePlan = existingResult.fold((_) => false, (list) => list.isNotEmpty);

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          hasActivePlan ? 'Reemplazar plan actual' : 'Agregar a la agenda',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          hasActivePlan
              ? 'Ya tienes un plan de tratamiento activo en tu agenda. '
                  'Agregar el plan para ${widget.diagnosis.diseaseName} en '
                  '${widget.diagnosis.cropName} lo va a reemplazar por completo. '
                  '¿Deseas continuar?'
              : '¿Deseas agregar un plan de tratamiento para '
                  '${widget.diagnosis.diseaseName} en ${widget.diagnosis.cropName} '
                  'a tu agenda agronómica?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'No agregar',
              style: GoogleFonts.inter(color: AppColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              elevation: 0,
            ),
            child: Text(
              hasActivePlan ? 'Reemplazar' : 'Agregar',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.forestGreen),
      ),
    );

    context.read<TreatmentBloc>().add(TreatmentGenerateFromDiagnosisRequested(
      diagnosisId: widget.diagnosis.id,
      diseaseName: widget.diagnosis.diseaseName,
      cropName: widget.diagnosis.cropName,
      llmDiagnostico: r.diagnostico,
      llmTratamiento: r.tratamiento,
      llmPrevencion: r.prevencion,
    ));
    final treatmentState = await context.read<TreatmentBloc>().stream.firstWhere(
          (s) => s is TreatmentAgendaLoaded || s is TreatmentFailure,
        );

    if (!mounted) return;
    Navigator.pop(context); // cierra el dialogo de carga

    if (treatmentState is TreatmentFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(treatmentState.message, style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isAddedToAgenda = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tratamiento agregado a la agenda',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.forestGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build principal
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.diagnosisBg,
        body: BlocListener<LlmDiagnosisCubit, LlmDiagnosisState>(
          listener: (context, state) {
            if (state is LlmDiagnosisLoaded) {
              if (widget.diagnosis.llmResponse == null) {
                context.read<DiagnosisBloc>().add(
                  DiagnosisLlmSaved(
                    diagnosisId: widget.diagnosis.id,
                    llmResponse: state.response,
                  ),
                );
              }
              context.read<ProductRecommendationCubit>().getRecommendations(
                disease: widget.diagnosis.diseaseName,
                crop: widget.diagnosis.cropName,
              );
            }
          },
          child: CustomScrollView(
            slivers: [
              DiagnosisHeroSliver(diagnosis: widget.diagnosis),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxlPlus),
                    DiagnosisSummaryCard(
                      diagnosis: widget.diagnosis,
                      userText: widget.userText,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    DiagnosisInfectionLevelBar(diagnosis: widget.diagnosis),
                    const SizedBox(height: AppSpacing.xl),
                    const DiagnosisRecommendationsSection(),
                    const SizedBox(height: AppSpacing.xl),
                    if (widget.diagnosis.statusLabel != 'Saludable')
                      BlocBuilder<LlmDiagnosisCubit, LlmDiagnosisState>(
                        builder: (context, state) {
                          if (state is! LlmDiagnosisLoaded) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              DiagnosisAgendaButton(
                                isAddedToAgenda: _isAddedToAgenda,
                                onAddPressed: _addToAgenda,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          );
                        },
                      ),
                    const DiagnosisProductsSection(),
                    const SizedBox(height: AppSpacing.xgiant),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
