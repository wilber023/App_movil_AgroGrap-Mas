import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'diagnosis_result_card.dart';

/// Tarjeta compacta para los estados transitorios de la explicacion IA
/// (cargando / error con reintentar) mientras `LlmDiagnosisCubit` resuelve.
class DiagnosisLlmLoadingCard extends StatelessWidget {
  const DiagnosisLlmLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DiagnosisResultCard(
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: AppColors.aSecondary, strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Preparando una explicación fácil de entender para ti...',
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class DiagnosisLlmErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const DiagnosisLlmErrorCard({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return DiagnosisResultCard(
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined, size: 18, color: AppColors.aOnSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No pudimos preparar la explicación ahora mismo.',
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Reintentar', style: AppTypography.etiquetaSm.copyWith(color: AppColors.aSecondary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
