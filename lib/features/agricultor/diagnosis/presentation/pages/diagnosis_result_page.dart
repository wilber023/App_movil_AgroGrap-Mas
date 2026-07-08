import 'dart:io';
import 'dart:math' as math;

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
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

const Color _bg = Color(0xFFF5F7F2);
const Color _textPrimary = Color(0xFF1B2D27);
const Color _textSecondary = Color(0xFF6B8F71);
const Color _track = Color(0xFFE2EBE6);
const Color _chipAmberBg = Color(0xFFFFF3E0);
const Color _chipAmberTxt = Color(0xFF7B4A10);
const Color _riskHigh = Color(0xFFD32F2F);
const Color _riskMed = Color(0xFFF57C00);
const Color _riskLow = Color(0xFF388E3C);
const Color _metricBlue = Color(0xFF1565C0);

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

  Box<String> get _agendaBox => sl<Box<String>>(instanceName: 'agendaBox');
  String get _agendaKey => 'agenda_added_${widget.diagnosis.id}';

  @override
  void initState() {
    super.initState();
    _isAddedToAgenda = _agendaBox.get(_agendaKey) != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.diagnosis.llmResponse == null) {
        context.read<LlmDiagnosisCubit>().consultar(
          diagnosis: widget.diagnosis,
          userText: widget.userText,
        );
      } else {
        context.read<ProductRecommendationCubit>().getRecommendations(
          disease: widget.diagnosis.diseaseName,
          crop: widget.diagnosis.cropName,
        );
      }
    });
  }

  Future<void> _addToAgenda() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Agregar a la agenda',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Deseas agregar un plan de tratamiento para '
          '${widget.diagnosis.diseaseName} en ${widget.diagnosis.cropName} '
          'a tu agenda agronómica?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'No agregar',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Agregar',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _agendaBox.put(_agendaKey, 'true');
    if (!mounted) return;
    setState(() => _isAddedToAgenda = true);
    context.read<TreatmentBloc>().add(const TreatmentAgendaRequested());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tratamiento agregado a la agenda',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.forestGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        backgroundColor: _bg,
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
                    const SizedBox(height: 16),
                    _buildSummaryCard(context),
                    const SizedBox(height: 12),
                    _buildInfectionBar(),
                    const SizedBox(height: 12),
                    _buildRecommendationsSection(context),
                    const SizedBox(height: 12),
                    if (widget.diagnosis.statusLabel != 'Saludable')
                      BlocBuilder<LlmDiagnosisCubit, LlmDiagnosisState>(
                        builder: (context, state) {
                          if (state is! LlmDiagnosisLoaded) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              _buildAgendaButton(),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
                    _buildProductsSection(context),
                    const SizedBox(height: 40),
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
      backgroundColor: const Color(0xFF0B1F18),
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.diagnosis.diseaseName,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
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
                        colors: [Color(0xFF0B1F18), Color(0xFF1B3A2A)],
                      ),
                    ),
                  ),
            // Gradiente oscuro para legibilidad
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x77000000), Color(0xCC000000)],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
            // Contenido sobre la imagen
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge "Diagnóstico completado"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B7A3C).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Diagnóstico completado',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Nombre de la enfermedad
                    Text(
                      widget.diagnosis.diseaseName,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Chips de cultivo + confianza
                    Row(
                      children: [
                        _heroChip('🌱 ${widget.diagnosis.cropName}'),
                        const SizedBox(width: 8),
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
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.28),
        width: 0.5,
      ),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
    ),
  );

  // ---------------------------------------------------------------------------
  // Tarjeta "Resumen del diagnóstico"
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCard(BuildContext context) {
    final conf = widget.diagnosis.confidence;
    final isHealthy = widget.diagnosis.statusLabel == 'Saludable';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _track, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              'Resumen del diagnóstico',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 0.5, color: _track),
          // Cuerpo LLM
          BlocBuilder<LlmDiagnosisCubit, LlmDiagnosisState>(
            builder: (context, state) {
              if (state is LlmDiagnosisIdle || state is LlmDiagnosisLoading) {
                return Padding(
                  padding: const EdgeInsets.all(16),
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
                      const SizedBox(width: 10),
                      Text(
                        'Generando análisis IA...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (state is LlmDiagnosisError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off_outlined,
                        size: 16,
                        color: _textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.message,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.read<LlmDiagnosisCubit>().consultar(
                              diagnosis: widget.diagnosis,
                              userText: widget.userText,
                            ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.forestGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
          ),
          Container(height: 0.5, color: _track),
          // Métricas
          Padding(
            padding: const EdgeInsets.all(14),
            child: _buildMetricTiles(conf, isHealthy),
          ),
          // Top-K colapsable
          if (widget.diagnosis.topK.length > 1) ...[
            Container(height: 0.5, color: _track),
            _buildTopKCollapsed(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryBody(LlmResponseEntity r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.avisos.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _chipAmberBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Color(0xFF7B4A10),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.avisos.join('\n'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _chipAmberTxt,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (r.diagnostico.isNotEmpty)
            Text(
              r.diagnostico,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: _textPrimary,
                height: 1.55,
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
      riskColor = _riskLow;
      gravLabel = 'Leve';
      gravColor = _riskLow;
    } else if (conf >= 0.85) {
      riskLabel = 'Alto';
      riskColor = _riskHigh;
      gravLabel = 'Severa';
      gravColor = _riskHigh;
    } else if (conf >= 0.65) {
      riskLabel = 'Moderado';
      riskColor = _riskMed;
      gravLabel = 'Moderada';
      gravColor = AppColors.forestGreen;
    } else {
      riskLabel = 'Bajo';
      riskColor = _riskLow;
      gravLabel = 'Leve';
      gravColor = _riskLow;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(width: 8),
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
          const SizedBox(width: 8),
          Expanded(
            child: _metricTile(
              icon: Icons.diamond_outlined,
              iconColor: _metricBlue,
              value: '${(conf * 100).toInt()}%',
              valueColor: _metricBlue,
              label: 'Confianza IA',
              sub: 'Análisis basado\nen modelo',
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: _track, width: 0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 8,
              color: _textSecondary.withValues(alpha: 0.75),
            ),
            maxLines: 2,
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
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(
          'Otras predicciones del modelo (${others.length})',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: _textSecondary,
        collapsedIconColor: _textSecondary,
        children: others.map(_buildTopKRow).toList(),
      ),
    );
  }

  Widget _buildTopKRow(TopKPrediction p) {
    final pct = (p.confidence * 100).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${p.cropName} · ${p.diseaseName}',
                  style: GoogleFonts.inter(fontSize: 11, color: _textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: p.confidence.clamp(0.0, 1.0),
                backgroundColor: _track,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _textSecondary.withValues(alpha: 0.45),
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
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _track, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nivel de infección detectado',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 18),
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
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4CAF50),
                          Color(0xFFFFC107),
                          Color(0xFFFF5722),
                          Color(0xFFD32F2F),
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
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFF57C00),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
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
          const SizedBox(height: 10),
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
                      ? _riskHigh
                      : _textSecondary.withValues(alpha: 0.65),
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
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _track, width: 0.5),
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
                  SizedBox(width: 8),
                  Text(
                    'Recomendaciones generales',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _textPrimary,
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
            iconColor: const Color(0xFFC45E0A),
            text: 'No fue posible cargar recomendaciones.',
          );
        }
        if (state is ProductRecommendationLoaded && state.products.isEmpty) {
          return _buildProductsStatusCard(
            icon: Icons.search_off_rounded,
            iconColor: _textSecondary,
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _track, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(fontSize: 12, color: _textSecondary),
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
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
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
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ordenados por costo-beneficio',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: _textSecondary,
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
            Color(0xFFF2F2F2),
            Color(0xFFE4E4E4),
            Color(0xFFF2F2F2),
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
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sBox(160, 15, grad),
                  const SizedBox(height: 5),
                  _sBox(120, 10, grad),
                ],
              ),
            ),
            _skeletonCard(grad),
            const SizedBox(height: 10),
            _skeletonCard(grad),
          ],
        );
      },
    );
  }

  Widget _skeletonCard(LinearGradient grad) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _track, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sBox(64, 64, grad, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _sBox(null, 13, grad)),
                    const SizedBox(width: 8),
                    _sBox(70, 13, grad),
                  ],
                ),
                const SizedBox(height: 5),
                _sBox(90, 10, grad),
                const SizedBox(height: 10),
                _sBox(null, 6, grad, radius: 3),
                const SizedBox(height: 8),
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

  static const _kFungicida = Color(0xFF1B7A3C);
  static const _kInsecticida = Color(0xFFC45E0A);
  static const _kHerbicida = Color(0xFF0A7A6B);
  static const _kFertilizante = Color(0xFF1A4DB5);
  static const _kBiologico = Color(0xFF6B1AA8);
  static const _kOther = Color(0xFF5C5C5C);

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
        color: const Color(0xFF2E7D32),
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
      color: const Color(0xFF455A64),
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
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _track, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            _buildImage(),
            const SizedBox(width: 12),
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
                            color: _textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
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
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 5, top: 1),
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
                              color: _textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Barra de eficacia
                  Row(
                    children: [
                      Text(
                        'Eficacia estimada',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: _textSecondary,
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
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: eff,
                        backgroundColor: _track,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.forestGreen,
                        ),
                      ),
                    ),
                  ),
                  // Badge
                  if (badge != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _BadgeChip(label: badge.label, color: badge.color),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            badge.desc,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: _textSecondary,
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
                    const SizedBox(height: 10),
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
        color: const Color(0xFFF0F4F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.eco_outlined,
        size: 28,
        color: AppColors.forestGreen,
      ),
    );

    if (product.imageUrl == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
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
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(4),
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
