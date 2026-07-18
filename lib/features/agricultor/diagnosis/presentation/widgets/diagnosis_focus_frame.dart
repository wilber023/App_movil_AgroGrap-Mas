import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import 'corner_bracket_painter.dart';

/// Marco de encuadre animado (pulso + esquinas) de [DiagnosisPage], con el
/// mensaje de guía rotativo mientras no hay foto capturada.
class DiagnosisFocusFrame extends StatelessWidget {
  const DiagnosisFocusFrame({
    super.key,
    required this.isCaptured,
    required this.pulseAnimation,
    required this.guideMessage,
    required this.guideMessageKey,
  });

  final bool isCaptured;
  final Animation<double> pulseAnimation;
  final String guideMessage;
  final Object guideMessageKey;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final fw = sw * 0.75;
    final fh = sh * 0.50;

    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: pulseAnimation,
          builder: (context, _) {
            final scale = isCaptured ? 1.0 : pulseAnimation.value;
            final bracketColor = isCaptured
                ? AppColors.warmAmber
                : AppColors.parcelsAddGreen;
            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: fw,
                height: fh,
                child: CustomPaint(
                  painter: CornerBracketPainter(
                    color: bracketColor.withValues(
                      alpha: isCaptured ? 1.0 : pulseAnimation.value,
                    ),
                    armLength: 26,
                    strokeWidth: 3,
                  ),
                  child: !isCaptured
                      ? Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              guideMessage,
                              key: ValueKey(guideMessageKey),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.onPrimary.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
