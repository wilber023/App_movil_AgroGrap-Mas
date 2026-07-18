import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../offline_knowledge/presentation/cubit/offline_knowledge_cubit.dart';
import '../../../../offline_knowledge/presentation/widgets/diagnosis_detail_view.dart';
import '../../domain/entities/diagnosis_entity.dart';
import 'diagnosis_llm_analysis_body.dart';
import 'diagnosis_metric_tiles.dart';
import 'diagnosis_topk_section.dart';

/// Tarjeta "Resumen del diagnóstico" de [DiagnosisResultPage]: cuerpo
/// offline u online (LLM), métricas de riesgo/gravedad/confianza y el
/// desplegable Top-K.
class DiagnosisSummaryCard extends StatelessWidget {
  const DiagnosisSummaryCard({
    super.key,
    required this.diagnosis,
    this.userText,
  });

  final DiagnosisEntity diagnosis;
  final String? userText;

  @override
  Widget build(BuildContext context) {
    final conf = diagnosis.confidence;
    final isHealthy = diagnosis.statusLabel == 'Saludable';

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
              return DiagnosisLlmAnalysisBody(
                diagnosis: diagnosis,
                userText: userText,
              );
            },
          ),
          Container(height: 0.5, color: AppColors.parcelsTrackGrey),
          // ── Métricas ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: DiagnosisMetricTiles(confidence: conf, isHealthy: isHealthy),
          ),
          // ── Top-K colapsable ─────────────────────────────────────────────
          if (diagnosis.topK.length > 1) ...[
            Container(height: 0.5, color: AppColors.parcelsTrackGrey),
            DiagnosisTopKSection(topK: diagnosis.topK),
          ],
        ],
      ),
    );
  }
}
