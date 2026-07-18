import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Sombra sutil compartida por las cards de [DiagnosisEntryAprendizPage] y
/// [DiagnosisResultAprendizPage], para que todo el feature se sienta parte
/// de un mismo sistema visual.
final List<BoxShadow> kAprendizDiagnosisCardShadow = [
  BoxShadow(color: AppColors.aOnSurface.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
];
