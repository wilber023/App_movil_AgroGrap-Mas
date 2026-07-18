import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Viñeta radial oscura sobre el visor de cámara en [DiagnosisPage], antes
/// de capturar una foto.
class DiagnosisVignetteOverlay extends StatelessWidget {
  const DiagnosisVignetteOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [
                AppColors.transparent,
                AppColors.black.withValues(alpha: 0.45),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
