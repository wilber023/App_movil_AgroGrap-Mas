import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Botón de acción secundario (icono + etiqueta) usado en las barras de
/// captura de [DiagnosisPage] (ej. "Historial", "Galería", "Repetir").
class DiagnosisIconButton extends StatelessWidget {
  const DiagnosisIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.onPrimary.withValues(alpha: isDisabled ? 0.3 : 0.7),
              size: 22,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.onPrimary.withValues(alpha: isDisabled ? 0.25 : 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón circular de disparo de [DiagnosisPage].
class DiagnosisShutterButton extends StatelessWidget {
  const DiagnosisShutterButton({super.key, required this.isCapturing, required this.onTap});

  final bool isCapturing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCapturing ? null : onTap,
      child: AnimatedOpacity(
        opacity: isCapturing ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.onPrimary.withValues(alpha: 0.35),
              width: 3,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.xs),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón circular "Analizar" mostrado en el panel post-captura de
/// [DiagnosisPage].
class DiagnosisAnalyzeButton extends StatelessWidget {
  const DiagnosisAnalyzeButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warmAmber,
            ),
            child: const Icon(
              Icons.search_outlined,
              color: AppColors.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Analizar',
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }
}
