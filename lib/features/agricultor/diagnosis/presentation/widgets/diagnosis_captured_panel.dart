import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'diagnosis_camera_controls.dart';

/// Panel mostrado tras capturar una foto en [DiagnosisPage]: campo de
/// síntomas opcional + acciones (repetir / analizar / galería).
class DiagnosisCapturedPanel extends StatelessWidget {
  const DiagnosisCapturedPanel({
    super.key,
    required this.symptomsController,
    required this.symptomsError,
    required this.onRetake,
    required this.onAnalyze,
    required this.onGallery,
  });

  final TextEditingController symptomsController;
  final String? symptomsError;
  final VoidCallback onRetake;
  final VoidCallback onAnalyze;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.xxl, AppSpacing.xxlPlus, bottomPad + AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.82),
        border: Border(
          top: BorderSide(
            color: AppColors.onPrimary.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Etiqueta del campo ──────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 11,
                color: AppColors.onPrimary.withValues(alpha: 0.65),
              ),
              const SizedBox(width: AppSpacing.xsPlus),
              Text(
                'SÍNTOMAS OBSERVADOS  ·  OPCIONAL',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: AppColors.onPrimary.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // ── Campo de texto ──────────────────────────────────────────────
          TextField(
            controller: symptomsController,
            maxLines: 2,
            maxLength: 400,
            style: GoogleFonts.inter(
              color: AppColors.onPrimary,
              fontSize: 12.5,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText:
                  'Ej: manchas amarillas en hojas, tallos negros, frutos caídos...',
              hintStyle: GoogleFonts.inter(
                color: AppColors.onPrimary.withValues(alpha: 0.50),
                fontSize: 11.5,
              ),
              errorText: symptomsError,
              errorStyle: GoogleFonts.inter(
                color: AppColors.errorBright,
                fontSize: 10.5,
                height: 1.4,
              ),
              errorMaxLines: 3,
              filled: true,
              fillColor: AppColors.onPrimary.withValues(alpha: 0.13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mdLg),
                borderSide: BorderSide(
                  color: AppColors.onPrimary.withValues(alpha: 0.28),
                  width: 0.8,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mdLg),
                borderSide: BorderSide(
                  color: AppColors.onPrimary.withValues(alpha: 0.28),
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mdLg),
                borderSide: const BorderSide(color: AppColors.parcelsAddGreen, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mdLg),
                borderSide: const BorderSide(
                  color: AppColors.errorBright,
                  width: 1.0,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mdLg),
                borderSide: const BorderSide(
                  color: AppColors.errorBright,
                  width: 1.5,
                ),
              ),
              counterStyle: GoogleFonts.inter(
                color: AppColors.onPrimary.withValues(alpha: 0.30),
                fontSize: 9,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
            ),
          ),
          // ── Botones ─────────────────────────────────────────────────────
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DiagnosisIconButton(
                  icon: Icons.refresh_outlined,
                  label: 'Repetir',
                  onTap: onRetake,
                ),
                DiagnosisAnalyzeButton(onTap: onAnalyze),
                DiagnosisIconButton(
                  icon: Icons.photo_outlined,
                  label: 'Galería',
                  onTap: onGallery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
