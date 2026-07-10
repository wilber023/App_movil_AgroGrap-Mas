import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'diagnosis_result_card.dart';

/// Tarjeta celebratoria cuando el cultivo esta sano. No aparece en la
/// imagen de referencia (que muestra el flujo de enfermedad detectada) —
/// se conserva tal cual el diseño actual, solo extraida a su propio widget.
class DiagnosisHealthyResultCard extends StatelessWidget {
  const DiagnosisHealthyResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DiagnosisResultCard(
      color: AppColors.aMint,
      borderColor: AppColors.aSecondaryContainer,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.aSecondaryContainer, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, color: AppColors.aSecondary, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            '¡Tu cultivo está sano!',
            style: AppTypography.agendaTitle.copyWith(fontSize: 21, color: AppColors.aSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'No encontramos señales de enfermedad. Sigue cuidando tu cultivo como hasta ahora.',
            style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
