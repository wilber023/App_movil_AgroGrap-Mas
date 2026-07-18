import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Barra superior del visor de [DiagnosisPage]: título y, si ya hay una
/// foto capturada, botón "Repetir".
class DiagnosisTopBar extends StatelessWidget {
  const DiagnosisTopBar({super.key, required this.isCaptured, required this.onRetake});

  final bool isCaptured;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: AppSpacing.none,
      right: AppSpacing.none,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
        color: AppColors.black.withValues(alpha: 0.55),
        child: Row(
          children: [
            // Botón "Repetir" solo cuando hay foto capturada
            if (isCaptured)
              GestureDetector(
                onTap: onRetake,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.onPrimary,
                    size: 18,
                  ),
                ),
              )
            else
              const SizedBox(width: AppSpacing.giantPlus),
            Expanded(
              child: Center(
                child: Text(
                  'Diagnóstico CNN',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
            // Espacio de balance
            const SizedBox(width: AppSpacing.giantPlus),
          ],
        ),
      ),
    );
  }
}
