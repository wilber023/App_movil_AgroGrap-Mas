import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../bloc/llm_diagnosis_cubit.dart';

/// Checklist "Recomendaciones generales" derivado de `LLM.prevencion`,
/// mostrado en [DiagnosisResultPage] una vez el diagnóstico IA está cargado.
class DiagnosisRecommendationsSection extends StatelessWidget {
  const DiagnosisRecommendationsSection({super.key});

  List<String> _parseLines(String text) => text
      .split('\n')
      .map((l) => l.trim().replaceFirst(RegExp(r'^[-•*\d.]+\s*'), ''))
      .where((l) => l.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
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
}
