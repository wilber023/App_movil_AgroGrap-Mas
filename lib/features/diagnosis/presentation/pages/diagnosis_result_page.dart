import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/services/cnn_engine/cnn_result.dart';
import '../../domain/entities/diagnosis_entity.dart';
import '../../domain/entities/llm_response_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/diagnosis_bloc.dart';
import '../bloc/llm_diagnosis_cubit.dart';
import '../cubit/product_recommendation_cubit.dart';
import '../../../treatment/presentation/bloc/treatment_bloc.dart';

// =============================================================================
// AgroGraph-MAS -- Resultado del Diagnóstico CNN + Asistente IA
// =============================================================================

const Color _bg = Color(0xFFF8FAF5);
const Color _textPrimary = Color(0xFF1B2D27);
const Color _textSecondary = Color(0xFF6B8F71);
const Color _trackGrey = Color(0xFFE2EBE6);
const Color _chipGreenBg = Color(0xFFEAF3DE);
const Color _chipGreenText = Color(0xFF27500A);
const Color _chipAmberBg = Color(0xFFFFF3E0);
const Color _chipAmberText = Color(0xFF7B4A10);

// Punto de entrada: provee el cubit y delega a la vista con estado.
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
// Vista interna con estado (campo de texto + llamada LLM)
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
        // Nueva diagnosis: LLM carga → BlocListener dispara productos al terminar
        context.read<LlmDiagnosisCubit>().consultar(
              diagnosis: widget.diagnosis,
              userText: widget.userText,
            );
      } else {
        // LLM ya cacheado: disparar productos de inmediato
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
        title: const Text(
          'Agregar a la agenda',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Deseas agregar un plan de tratamiento para '
          '${widget.diagnosis.diseaseName} en ${widget.diagnosis.cropName} '
          'a tu agenda agronómica?',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'No agregar',
              style: TextStyle(fontFamily: 'Inter', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text(
              'Agregar',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _agendaBox.put(_agendaKey, 'true');
    if (!mounted) return;
    setState(() => _isAddedToAgenda = true);
    // Refresca la agenda para que aparezca inmediatamente
    context.read<TreatmentBloc>().add(const TreatmentAgendaRequested());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Tratamiento agregado a la agenda',
          style: TextStyle(fontFamily: 'Inter'),
        ),
        backgroundColor: AppColors.forestGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2D27),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Resultado del diagnóstico',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
      body: BlocListener<LlmDiagnosisCubit, LlmDiagnosisState>(
        listener: (context, state) {
          if (state is LlmDiagnosisLoaded) {
            // Persistir en Hive solo si es respuesta nueva
            if (widget.diagnosis.llmResponse == null) {
              context.read<DiagnosisBloc>().add(DiagnosisLlmSaved(
                    diagnosisId: widget.diagnosis.id,
                    llmResponse: state.response,
                  ));
            }
            // Disparar productos en cuanto el LLM confirma el diagnóstico
            context.read<ProductRecommendationCubit>().getRecommendations(
                  disease: widget.diagnosis.diseaseName,
                  crop: widget.diagnosis.cropName,
                );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              _buildHeroCard(),
              if (widget.diagnosis.topK.length > 1) ...[
                const SizedBox(height: 8),
                _buildTopKSection(),
              ],
              const SizedBox(height: 8),
              _buildLlmSection(context),
              const SizedBox(height: 8),
              // Botón de agenda: solo si hay LLM cargado y la planta no está sana
              if (widget.diagnosis.statusLabel != 'Saludable')
                BlocBuilder<LlmDiagnosisCubit, LlmDiagnosisState>(
                  builder: (context, llmState) {
                    if (llmState is! LlmDiagnosisLoaded) {
                      return const SizedBox.shrink();
                    }
                    return _buildAgendaButton();
                  },
                ),
              const SizedBox(height: 8),
              _buildProductsSection(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Botón de agenda
  // ---------------------------------------------------------------------------

  Widget _buildAgendaButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: SizedBox(
        width: double.infinity,
        child: _isAddedToAgenda
            ? OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text(
                  'Tratamiento en agenda',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forestGreen,
                  disabledForegroundColor: AppColors.forestGreen,
                  side: const BorderSide(
                      color: AppColors.forestGreen, width: 0.8),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              )
            : ElevatedButton.icon(
                onPressed: _addToAgenda,
                icon: const Icon(Icons.event_note_outlined, size: 16),
                label: const Text(
                  'Agregar tratamiento a la agenda',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sección CNN: hero card
  // ---------------------------------------------------------------------------

  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _trackGrey, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.diagnosis.diseaseName,
            style: AppTypography.tituloMd.copyWith(
              color: _textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _pill(widget.diagnosis.cropName, _chipGreenBg, _chipGreenText),
              const SizedBox(width: 6),
              _pill(widget.diagnosis.diseaseName, _chipGreenBg, _chipGreenText),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Confianza del modelo CNN',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: _textSecondary,
                ),
              ),
              Text(
                '${(widget.diagnosis.confidence * 100).toInt()}%',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.forestGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _trackGrey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widget.diagnosis.confidence.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Modelo local · EfficientNetB4 · sin API externa',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: Color(0xFFADB5BD),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: widget.diagnosis.imagePath != null &&
                      File(widget.diagnosis.imagePath!).existsSync()
                  ? Image.file(
                      File(widget.diagnosis.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFFD8EAD0),
                      child: const Icon(
                        Icons.eco_outlined,
                        color: AppColors.forestGreen,
                        size: 48,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sección CNN: top-K
  // ---------------------------------------------------------------------------

  Widget _buildTopKSection() {
    final others = widget.diagnosis.topK.skip(1).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _trackGrey, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Otras predicciones del modelo',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...others.map((p) => _buildTopKRow(p)),
          ],
        ),
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
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _trackGrey,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: p.confidence.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _textSecondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sección LLM: campo de texto + botón + respuesta
  // ---------------------------------------------------------------------------

  Widget _buildLlmSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: BlocBuilder<LlmDiagnosisCubit, LlmDiagnosisState>(
        builder: (context, state) {
          if (state is LlmDiagnosisIdle || state is LlmDiagnosisLoading) {
            return _buildSuggestionsLoadingCard();
          }
          if (state is LlmDiagnosisError) {
            return _buildSuggestionsErrorCard(context, state.message);
          }
          if (state is LlmDiagnosisLoaded) {
            return _buildLlmResultCard(state.response);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSuggestionsLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _trackGrey, width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: AppColors.forestGreen,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Cargando sugerencias IA...',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsErrorCard(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _trackGrey, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined, size: 16, color: _textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: _textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.read<LlmDiagnosisCubit>().consultar(
                  diagnosis: widget.diagnosis,
                  userText: widget.userText,
                ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.forestGreen,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Reintentar',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLlmResultCard(LlmResponseEntity r) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _trackGrey, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con confianza ajustada
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 14, color: AppColors.forestGreen),
                const SizedBox(width: 6),
                const Text(
                  'Resultado del asistente IA',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const Spacer(),
                _estadoBadge(r.estado),
              ],
            ),
          ),
          if (r.confianzaAjustada > 0) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Confianza ajustada',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: _textSecondary,
                    ),
                  ),
                  Text(
                    '${(r.confianzaAjustada * 100).toInt()}%',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
          _divider(),
          // Avisos (si existen)
          if (r.avisos.isNotEmpty) ...[
            _sectionBlock(
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFF7B4A10),
              bgColor: _chipAmberBg,
              label: 'Aviso',
              content: r.avisos.join('\n'),
              textColor: _chipAmberText,
            ),
            _divider(),
          ],
          // Diagnóstico IA
          if (r.diagnostico.isNotEmpty) ...[
            _sectionBlock(
              icon: Icons.biotech_outlined,
              label: 'Diagnóstico',
              content: r.diagnostico,
            ),
            _divider(),
          ],
          // Tratamiento
          if (r.tratamiento.isNotEmpty) ...[
            _sectionBlock(
              icon: Icons.healing_outlined,
              label: 'Tratamiento',
              content: r.tratamiento,
            ),
            _divider(),
          ],
          // Prevención
          if (r.prevencion.isNotEmpty) ...[
            _sectionBlock(
              icon: Icons.shield_outlined,
              label: 'Prevención',
              content: r.prevencion,
            ),
          ],
          // Fuentes
          if (r.fuentes.isNotEmpty) ...[
            _divider(),
            _sourcesBlock(r.fuentes),
          ],
          if (r.sinDocumentos) ...[
            _divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Text(
                'No se encontraron documentos de referencia. La respuesta es generada por el modelo sin base documental.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: _textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _sectionBlock({
    required IconData icon,
    required String label,
    required String content,
    Color iconColor = AppColors.forestGreen,
    Color? bgColor,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 5),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: bgColor != null
                ? const EdgeInsets.all(8)
                : EdgeInsets.zero,
            decoration: bgColor != null
                ? BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            child: Text(
              content,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: textColor ?? _textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourcesBlock(List<String> fuentes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 13, color: _textSecondary),
              SizedBox(width: 5),
              Text(
                'FUENTES',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...fuentes.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: _textSecondary)),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: _textSecondary,
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
  }

  Widget _estadoBadge(String estado) {
    Color bg;
    Color text;
    String label;
    switch (estado) {
      case 'reforzado':
        bg = _chipGreenBg;
        text = _chipGreenText;
        label = 'Reforzado';
      case 'posible_contradiccion':
        bg = _chipAmberBg;
        text = _chipAmberText;
        label = 'Revisar';
      default:
        bg = _trackGrey;
        text = _textSecondary;
        label = 'Analizado';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: text,
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 0.5,
        color: _trackGrey,
        margin: const EdgeInsets.symmetric(horizontal: 14),
      );

  Widget _pill(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          color: textCol,
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
        if (state is ProductRecommendationIdle) return const SizedBox.shrink();
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _trackGrey, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: _textSecondary,
                ),
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
        _buildProductsSectionHeader(),
        const SizedBox(height: 12),
        ...state.products.asMap().entries.map(
          (e) => Padding(
            padding: EdgeInsets.only(
              bottom: e.key < state.products.length - 1 ? 10 : 0,
            ),
            child: _ProductCard(product: e.value),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.forestGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Productos Recomendados',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Para: ${widget.diagnosis.diseaseName} · '
                '${widget.diagnosis.cropName}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Skeleton loader para productos
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
          colors: const [Color(0xFFF2F2F2), Color(0xFFE4E4E4), Color(0xFFF2F2F2)],
          stops: [
            (t - 0.3).clamp(0.0, 1.0),
            t.clamp(0.0, 1.0),
            (t + 0.3).clamp(0.0, 1.0),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _trackGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sBox(150, 13, grad),
                      const SizedBox(height: 5),
                      _sBox(110, 10, grad),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _trackGrey, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sBox(72, 72, grad, radius: 8),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _sBox(null, 13, grad)),
                          const SizedBox(width: 8),
                          _sBox(64, 18, grad, radius: 4),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _sBox(90, 10, grad),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: _trackGrey),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sBox(double.infinity, 11, grad),
                const SizedBox(height: 5),
                _sBox(210, 11, grad),
                const SizedBox(height: 5),
                _sBox(170, 11, grad),
              ],
            ),
          ),
          Container(height: 0.5, color: _trackGrey),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                _sBox(110, 16, grad),
                const Spacer(),
                _sBox(100, 32, grad, radius: 8),
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
// Tarjeta de producto (diseño rico)
// =============================================================================

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductEntity product;

  static const _kFungicida    = Color(0xFF1B7A3C);
  static const _kInsecticida  = Color(0xFFC45E0A);
  static const _kHerbicida    = Color(0xFF0A7A6B);
  static const _kFertilizante = Color(0xFF1A4DB5);
  static const _kBiologico    = Color(0xFF6B1AA8);
  static const _kOther        = Color(0xFF5C5C5C);

  Color _typeColor() => switch (product.productType?.toLowerCase()) {
    'fungicida'                    => _kFungicida,
    'insecticida'                  => _kInsecticida,
    'herbicida'                    => _kHerbicida,
    'fertilizante'                 => _kFertilizante,
    'biológico' || 'biologico'     => _kBiologico,
    _                              => _kOther,
  };

  String _cropEmoji(String c) => switch (c.toLowerCase()) {
    'tomate'          => '🍅',
    'maiz' || 'maíz' => '🌽',
    'papa'            => '🥔',
    'frijol'          => '🫘',
    'calabaza'        => '🍈',
    'chile'           => '🌶️',
    _                 => '🌿',
  };

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBody = product.description != null ||
        product.targetDiseases.isNotEmpty ||
        product.targetCrops.isNotEmpty;
    final hasStock = product.stockStatus == 'in_stock' ||
        product.stockStatus == 'out_of_stock';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _trackGrey, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (hasBody) ...[
            _divider(),
            _buildBody(),
          ],
          if (hasStock) ...[
            _divider(),
            _buildStockRow(),
          ],
          _divider(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 0.5, color: _trackGrey);

  // --- Header: imagen + nombre + marca + badge ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (product.productType != null) ...[
                      const SizedBox(width: 8),
                      _TypeBadge(
                        label: product.productType!.toUpperCase(),
                        color: _typeColor(),
                      ),
                    ],
                  ],
                ),
                if (product.brand != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.brand!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    const sz = 72.0;
    final placeholder = Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.eco_outlined, size: 30, color: AppColors.forestGreen),
    );

    if (product.imageUrl == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        product.imageUrl!,
        width: sz,
        height: sz,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                width: sz,
                height: sz,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F0),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  // --- Body: ingrediente, enfermedades, cultivos ---

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.description != null)
            _InfoRow(
              emoji: '🧪',
              label: 'Ingrediente activo',
              value: product.description!,
            ),
          if (product.targetDiseases.isNotEmpty) ...[
            if (product.description != null) const SizedBox(height: 7),
            _InfoRow(
              emoji: '🦠',
              label: 'Trata',
              value: product.targetDiseases.take(4).join(' · '),
            ),
          ],
          if (product.targetCrops.isNotEmpty) ...[
            if (product.description != null ||
                product.targetDiseases.isNotEmpty)
              const SizedBox(height: 7),
            _InfoRow(
              emoji: '🌱',
              label: 'Cultivos',
              value: product.targetCrops
                  .take(4)
                  .map((c) => '${_cropEmoji(c)} $c')
                  .join(' · '),
            ),
          ],
        ],
      ),
    );
  }

  // --- Stock ---

  Widget _buildStockRow() {
    final inStock = product.stockStatus == 'in_stock';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            inStock ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 13,
            color: inStock ? AppColors.forestGreen : const Color(0xFFD32F2F),
          ),
          const SizedBox(width: 5),
          Text(
            inStock ? 'Disponible' : 'Sin stock',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: inStock ? AppColors.forestGreen : const Color(0xFFD32F2F),
            ),
          ),
        ],
      ),
    );
  }

  // --- Footer: precio + botón ---

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              product.price,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.forestGreen,
              ),
            ),
          ),
          if (product.purchaseUrl != null)
            FilledButton.icon(
              onPressed: () => _launch(product.purchaseUrl!),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.open_in_new, size: 12),
              label: const Text(
                'Ver producto',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helpers de producto
// =============================================================================

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.emoji,
    required this.label,
    required this.value,
  });
  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12, height: 1.5)),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                    height: 1.5,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: _textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
