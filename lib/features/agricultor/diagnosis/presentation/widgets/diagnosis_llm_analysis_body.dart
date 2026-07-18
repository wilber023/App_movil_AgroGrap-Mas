import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/diagnosis_entity.dart';
import '../../domain/entities/llm_response_entity.dart';
import '../bloc/llm_diagnosis_cubit.dart';

/// Cuerpo online (LLM) de [DiagnosisSummaryCard]: estado de carga/error del
/// análisis IA y, una vez cargado, el texto de diagnóstico con su propio
/// "Ver más/Ver menos" (estado puramente local a este widget).
class DiagnosisLlmAnalysisBody extends StatefulWidget {
  const DiagnosisLlmAnalysisBody({
    super.key,
    required this.diagnosis,
    this.userText,
  });

  final DiagnosisEntity diagnosis;
  final String? userText;

  @override
  State<DiagnosisLlmAnalysisBody> createState() => _DiagnosisLlmAnalysisBodyState();
}

class _DiagnosisLlmAnalysisBodyState extends State<DiagnosisLlmAnalysisBody> {
  bool _diagnosticoExpanded = false;
  static const _diagnosticoCollapsedLines = 4;
  static const _diagnosticoCollapseThreshold = 220;

  @override
  Widget build(BuildContext context) {
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
}
