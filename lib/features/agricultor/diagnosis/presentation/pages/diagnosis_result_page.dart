import 'dart:io';
import 'dart:math' as math;

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/network_info.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../treatment/domain/usecases/treatment_usecases.dart';
import '../../../../offline_knowledge/domain/cultivo_slug.dart';
import '../../../../offline_knowledge/presentation/cubit/offline_knowledge_cubit.dart';
import '../../../../offline_knowledge/presentation/widgets/diagnosis_detail_view.dart';
import '../../data/services/cnn_engine/cnn_result.dart';
import '../../domain/entities/diagnosis_entity.dart';
import '../../domain/entities/llm_response_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/diagnosis_bloc.dart';
import '../bloc/llm_diagnosis_cubit.dart';
import '../cubit/product_recommendation_cubit.dart';
import '../../../treatment/presentation/bloc/treatment_bloc.dart';

// =============================================================================
// Paleta de colores
// =============================================================================


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

  // "Ver más/Ver menos" del texto de diagnóstico generado por el modelo,
  // en la tarjeta "Resumen del diagnóstico".
  bool _diagnosticoExpanded = false;
  static const _diagnosticoCollapsedLines = 4;
  static const _diagnosticoCollapseThreshold = 220;


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
              _buildSliverHero(context),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxlPlus),
                    _buildSummaryCard(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildInfectionBar(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildRecommendationsSection(context),
                    const SizedBox(height: AppSpacing.xl),
                    if (widget.diagnosis.statusLabel != 'Saludable')
                      BlocBuilder<LlmDiagnosisCubit, LlmDiagnosisState>(
                        builder: (context, state) {
                          if (state is! LlmDiagnosisLoaded) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              _buildAgendaButton(),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          );
                        },
                      ),
                    _buildProductsSection(context),
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

  // ---------------------------------------------------------------------------
  // Hero (SliverAppBar)
  // ---------------------------------------------------------------------------

  Widget _buildSliverHero(BuildContext context) {
    final imagePath = widget.diagnosis.imagePath;
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
        widget.diagnosis.diseaseName,
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
                      widget.diagnosis.diseaseName,
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
                        _heroChip('🌱 ${widget.diagnosis.cropName}'),
                        const SizedBox(width: AppSpacing.md),
                        _heroChip(
                          'Alta confianza '
                          '${(widget.diagnosis.confidence * 100).toInt()}%',
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

  // ---------------------------------------------------------------------------
  // Tarjeta "Resumen del diagnóstico"
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCard(BuildContext context) {
    final conf = widget.diagnosis.confidence;
    final isHealthy = widget.diagnosis.statusLabel == 'Saludable';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
        border: Border.all(color: AppColors.parcelsTrackGrey, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado con gradiente verde ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.xxl, AppSpacing.xxlPlus, AppSpacing.xxl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.forestGreen.withValues(alpha: 0.10),
                  AppColors.forestGreen.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xxlPlus),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.biotech_outlined,
                    size: 18,
                    color: AppColors.forestGreen,
                  ),
                ),
                const SizedBox(width: AppSpacing.lgXl),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen del diagnóstico',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.parcelsTextPrimary,
                      ),
                    ),
                    Text(
                      'Análisis generado por IA agrícola',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.parcelsTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.parcelsTrackGrey),
          // ── Cuerpo: offline u online ─────────────────────────────────────
          BlocBuilder<OfflineKnowledgeCubit, OfflineKnowledgeState>(
            builder: (context, offlineState) {
              if (offlineState is OfflineKnowledgeLoaded) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxlPlus),
                  child: DiagnosisDetailView(detail: offlineState.detail),
                );
              }
              return _buildLlmBody(context);
            },
          ),
          Container(height: 0.5, color: AppColors.parcelsTrackGrey),
          // ── Métricas ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: _buildMetricTiles(conf, isHealthy),
          ),
          // ── Top-K colapsable ─────────────────────────────────────────────
          if (widget.diagnosis.topK.length > 1) ...[
            Container(height: 0.5, color: AppColors.parcelsTrackGrey),
            _buildTopKCollapsed(),
          ],
        ],
      ),
    );
  }

  Widget _buildLlmBody(BuildContext context) {
    return BlocBuilder<LlmDiagnosisCubit, LlmDiagnosisState>(
      builder: (context, state) {
        if (state is LlmDiagnosisIdle || state is LlmDiagnosisLoading) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xxlPlus),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: AppColors.forestGreen,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Text(
                  'Generando análisis IA...',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.parcelsTextSecondary),
                ),
              ],
            ),
          );
        }
        if (state is LlmDiagnosisError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xxlPlus),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_outlined,
                  size: 16,
                  color: AppColors.parcelsTextSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    state.message,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.parcelsTextSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<LlmDiagnosisCubit>().consultar(
                    diagnosis: widget.diagnosis,
                    rol: 'agricultor',
                    userText: widget.userText,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.forestGreen,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  ),
                  child: Text(
                    'Reintentar',
                    style: GoogleFonts.inter(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is LlmDiagnosisLoaded) {
          return _buildSummaryBody(state.response);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSummaryBody(LlmResponseEntity r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avisos (ámbar) ────────────────────────────────────────────
          if (r.avisos.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.parcelsChipFollowBg,
                borderRadius: BorderRadius.circular(AppRadius.mdLg),
                border: Border.all(
                  color: AppColors.diagnosisAmberBorder,
                  width: 0.8,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: AppColors.parcelsChipFollowText,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      r.avisos.join('\n'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.parcelsChipFollowText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          // ── Texto diagnóstico IA ───────────────────────────────────────
          // Border con colores no uniformes + borderRadius no es válido en
          // Flutter (lanza "borderRadius can only be given on borders with
          // uniform colors"). Se usa clipBehavior + Border.all uniforme y el
          // acento izquierdo como Container separado dentro de un Stack.
          if (r.diagnostico.isNotEmpty)
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.diagnosisAnalysisCardBg,
                borderRadius: BorderRadius.circular(AppRadius.lgXl),
                border: Border.all(
                  color: AppColors.forestGreen.withValues(alpha: 0.18),
                  width: 0.8,
                ),
              ),
              child: Stack(
                children: [
                  // Acento izquierdo (reemplaza el left border de color sólido)
                  Positioned(
                    left: AppSpacing.none,
                    top: AppSpacing.none,
                    bottom: AppSpacing.none,
                    child: Container(width: AppSpacing.xxsPlus, color: AppColors.forestGreen),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xxlMid, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Etiqueta "Análisis IA"
                        Row(
                          children: [
                            const Icon(
                              Icons.psychology_outlined,
                              size: 13,
                              color: AppColors.forestGreen,
                            ),
                            const SizedBox(width: AppSpacing.xsPlus),
                            Text(
                              'Análisis IA',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.forestGreen,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Texto expandible
                        Text(
                          r.diagnostico,
                          maxLines: _diagnosticoExpanded
                              ? null
                              : _diagnosticoCollapsedLines,
                          overflow: _diagnosticoExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.parcelsTextPrimary,
                            height: 1.6,
                          ),
                        ),
                        // Botón "Ver más / Ver menos"
                        if (r.diagnostico.length > _diagnosticoCollapseThreshold) ...[
                          const SizedBox(height: AppSpacing.lg),
                          GestureDetector(
                            onTap: () => setState(
                              () => _diagnosticoExpanded = !_diagnosticoExpanded,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lgXl,
                                vertical: AppSpacing.xsPlus,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.forestGreen.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _diagnosticoExpanded ? 'Ver menos' : 'Ver más',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.forestGreen,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xxsPlus),
                                  Icon(
                                    _diagnosticoExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 14,
                                    color: AppColors.forestGreen,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tiles de métricas (Riesgo / Gravedad / Confianza IA)
  // ---------------------------------------------------------------------------

  Widget _buildMetricTiles(double conf, bool isHealthy) {
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

  // ---------------------------------------------------------------------------
  // Top-K colapsable
  // ---------------------------------------------------------------------------

  Widget _buildTopKCollapsed() {
    final others = widget.diagnosis.topK.skip(1).toList();
    if (others.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.none),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.none, AppSpacing.xxlPlus, AppSpacing.xl),
        title: Text(
          'Otras predicciones del modelo (${others.length})',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.parcelsTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: AppColors.parcelsTextSecondary,
        collapsedIconColor: AppColors.parcelsTextSecondary,
        children: others.map(_buildTopKRow).toList(),
      ),
    );
  }

  Widget _buildTopKRow(TopKPrediction p) {
    final pct = (p.confidence * 100).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${p.cropName} · ${p.diseaseName}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.parcelsTextPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.parcelsTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxsPlus),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: p.confidence.clamp(0.0, 1.0),
                backgroundColor: AppColors.parcelsTrackGrey,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.parcelsTextSecondary.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Barra de nivel de infección
  // ---------------------------------------------------------------------------

  Widget _buildInfectionBar() {
    final isHealthy = widget.diagnosis.statusLabel == 'Saludable';
    final position = isHealthy
        ? 0.06
        : widget.diagnosis.confidence.clamp(0.0, 1.0);

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

  // ---------------------------------------------------------------------------
  // Recomendaciones generales (checklist desde LLM.prevencion)
  // ---------------------------------------------------------------------------

  List<String> _parseLines(String text) => text
      .split('\n')
      .map((l) => l.trim().replaceFirst(RegExp(r'^[-•*\d.]+\s*'), ''))
      .where((l) => l.isNotEmpty)
      .toList();

  Widget _buildRecommendationsSection(BuildContext context) {
    return BlocBuilder<LlmDiagnosisCubit, LlmDiagnosisState>(
      builder: (context, state) {
        if (state is! LlmDiagnosisLoaded) return const SizedBox.shrink();
        final items = _parseLines(state.response.prevencion);
        if (items.isEmpty) return const SizedBox.shrink();
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
              Row(
                children: [
                  Icon(
                    Icons.eco_rounded,
                    size: 16,
                    color: AppColors.forestGreen,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Text(
                    'Recomendaciones generales',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.parcelsTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.hairline),
                        child: Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.parcelsTextPrimary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Botón de agenda (lógica sin cambios)
  // ---------------------------------------------------------------------------

  Widget _buildAgendaButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: SizedBox(
        width: double.infinity,
        child: _isAddedToAgenda
            ? OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: Text(
                  'Tratamiento en agenda',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forestGreen,
                  disabledForegroundColor: AppColors.forestGreen,
                  side: const BorderSide(
                    color: AppColors.forestGreen,
                    width: 0.8,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xlPlus),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.mdLg),
                  ),
                ),
              )
            : ElevatedButton.icon(
                onPressed: _addToAgenda,
                icon: const Icon(Icons.event_note_outlined, size: 16),
                label: Text(
                  'Agregar tratamiento a la agenda',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xlPlus),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.mdLg),
                  ),
                  elevation: 0,
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sección de productos recomendados
  // ---------------------------------------------------------------------------

  Widget _buildProductsSection(BuildContext context) {
    return BlocBuilder<ProductRecommendationCubit, ProductRecommendationState>(
      builder: (context, state) {
        if (state is ProductRecommendationIdle) {
          return const SizedBox.shrink();
        }
        if (state is ProductRecommendationLoading) {
          return const _ProductsSkeletonLoader();
        }
        if (state is ProductRecommendationError) {
          return _buildProductsStatusCard(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.diagnosisInsecticida,
            text: 'No fue posible cargar recomendaciones.',
          );
        }
        if (state is ProductRecommendationLoaded && state.products.isEmpty) {
          return _buildProductsStatusCard(
            icon: Icons.search_off_rounded,
            iconColor: AppColors.parcelsTextSecondary,
            text: 'No se encontraron productos para esta enfermedad.',
          );
        }
        if (state is ProductRecommendationLoaded) {
          return _buildProductsLoaded(state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProductsStatusCard({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.onPrimary,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.parcelsTrackGrey, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.parcelsTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsLoaded(ProductRecommendationLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de sección
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.none, AppSpacing.xxl, AppSpacing.xxl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Productos recomendados',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.parcelsTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Ordenados por costo-beneficio',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.parcelsTextSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Ver todos',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forestGreen,
                ),
              ),
            ],
          ),
        ),
        // Tarjetas de productos
        ...state.products.asMap().entries.map(
          (e) => _ProductCard(product: e.value, index: e.key),
        ),
      ],
    );
  }
}

// =============================================================================
// Skeleton loader (sin cambios)
// =============================================================================

class _ProductsSkeletonLoader extends StatefulWidget {
  const _ProductsSkeletonLoader();

  @override
  State<_ProductsSkeletonLoader> createState() =>
      _ProductsSkeletonLoaderState();
}

class _ProductsSkeletonLoaderState extends State<_ProductsSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final grad = LinearGradient(
          colors: const [
            AppColors.diagnosisSkeletonLight,
            AppColors.diagnosisSkeletonDark,
            AppColors.diagnosisSkeletonLight,
          ],
          stops: [
            (t - 0.3).clamp(0.0, 1.0),
            t.clamp(0.0, 1.0),
            (t + 0.3).clamp(0.0, 1.0),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.none, AppSpacing.xxl, AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sBox(160, 15, grad),
                  const SizedBox(height: AppSpacing.xsPlus),
                  _sBox(120, 10, grad),
                ],
              ),
            ),
            _skeletonCard(grad),
            const SizedBox(height: AppSpacing.lg),
            _skeletonCard(grad),
          ],
        );
      },
    );
  }

  Widget _skeletonCard(LinearGradient grad) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.parcelsTrackGrey, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sBox(64, 64, grad, radius: 10),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _sBox(null, 13, grad)),
                    const SizedBox(width: AppSpacing.md),
                    _sBox(70, 13, grad),
                  ],
                ),
                const SizedBox(height: AppSpacing.xsPlus),
                _sBox(90, 10, grad),
                const SizedBox(height: AppSpacing.lg),
                _sBox(null, 6, grad, radius: 3),
                const SizedBox(height: AppSpacing.md),
                _sBox(100, 20, grad, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sBox(double? w, double h, LinearGradient grad, {double radius = 4}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// =============================================================================
// Tarjeta de producto — diseño compacto horizontal
// =============================================================================

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.index});

  final ProductEntity product;
  final int index;

  static const _kFungicida = AppColors.diagnosisCompletedBadge;
  static const _kInsecticida = AppColors.diagnosisInsecticida;
  static const _kHerbicida = AppColors.diagnosisHerbicida;
  static const _kFertilizante = AppColors.diagnosisFertilizante;
  static const _kBiologico = AppColors.diagnosisBiologico;
  static const _kOther = AppColors.diagnosisOtherProduct;

  Color get _typeColor => switch (product.productType?.toLowerCase()) {
    'fungicida' => _kFungicida,
    'insecticida' => _kInsecticida,
    'herbicida' => _kHerbicida,
    'fertilizante' => _kFertilizante,
    'biológico' || 'biologico' => _kBiologico,
    _ => _kOther,
  };

  double get _efficacy {
    if (product.rating != null) {
      return (product.rating! / 5.0).clamp(0.0, 1.0);
    }
    const fallbacks = [0.88, 0.82, 0.76, 0.70];
    return fallbacks[math.min(index, fallbacks.length - 1)];
  }

  // Devuelve (etiqueta, color, descripción) del badge
  ({String label, Color color, String desc})? get _badge {
    final type = product.productType?.toLowerCase() ?? '';
    if (type == 'biológico' || type == 'biologico') {
      return (
        label: 'ECOLÓGICO',
        color: AppColors.diagnosisEcoBadge,
        desc: 'Mejora la salud del suelo y la planta.',
      );
    }
    if (index == 0) {
      return (
        label: 'MEJOR OPCIÓN',
        color: AppColors.forestGreen,
        desc: 'Excelente efecto prolongado.',
      );
    }
    return (
      label: 'MÁS ECONÓMICO',
      color: AppColors.diagnosisEconomicBadge,
      desc: 'Alternativa preventiva de amplio espectro.',
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final eff = _efficacy;
    final effPct = (eff * 100).round();
    final typeStr = product.productType != null
        ? product.productType![0].toUpperCase() +
              product.productType!.substring(1)
        : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.none, AppSpacing.xxl, AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.parcelsTrackGrey, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            _buildImage(),
            const SizedBox(width: AppSpacing.xl),
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + precio
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.parcelsTextPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        product.price,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  // Tipo + marca
                  if (typeStr != null) ...[
                    const SizedBox(height: AppSpacing.xxsPlus),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: AppSpacing.xsPlus, top: AppSpacing.hairline),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _typeColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            typeStr +
                                (product.brand != null
                                    ? ' · ${product.brand}'
                                    : ''),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.parcelsTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  // Barra de eficacia
                  Row(
                    children: [
                      Text(
                        'Eficacia estimada',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppColors.parcelsTextSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$effPct%',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xsPlus),
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: eff,
                        backgroundColor: AppColors.parcelsTrackGrey,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.forestGreen,
                        ),
                      ),
                    ),
                  ),
                  // Badge
                  if (badge != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _BadgeChip(label: badge.label, color: badge.color),
                        const SizedBox(width: AppSpacing.smMd),
                        Expanded(
                          child: Text(
                            badge.desc,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppColors.parcelsTextSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Enlace
                  if (product.purchaseUrl != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _launch(product.purchaseUrl!),
                        child: Text(
                          'Ver producto →',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    const sz = 64.0;
    final placeholder = Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        color: AppColors.diagnosisProductImageBg,
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
      ),
      child: const Icon(
        Icons.eco_outlined,
        size: 28,
        color: AppColors.forestGreen,
      ),
    );

    if (product.imageUrl == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.mdLg),
      child: Image.network(
        product.imageUrl!,
        width: sz,
        height: sz,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : placeholder,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

// =============================================================================
// Badge chip de producto
// =============================================================================

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd, vertical: AppSpacing.xxsPlus),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: color.withValues(alpha: 0.30), width: 0.5),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.4,
      ),
    ),
  );
}
