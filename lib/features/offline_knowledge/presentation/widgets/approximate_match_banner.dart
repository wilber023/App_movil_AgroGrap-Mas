// =============================================================================
// AgroGraph-MAS — ApproximateMatchBanner (offline_knowledge)
// Ver agrograph_diagnostico_offline_embeddings.md, sección 7.1 (semanticFallback).
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Banner amber para `DiagnosisSource.semanticFallback`: resultado
/// aproximado por similitud, con CTA para actualizar el paquete del cultivo.
///
/// Reutiliza el mismo lenguaje visual del banner offline global
/// (`core/widgets/shared_components.dart`), con el ícono y tono ámbar
/// reservado para CTAs (`AppColors.warmAmber`).
class ApproximateMatchBanner extends StatelessWidget {
  final String cultivo;
  final double score;

  /// Placeholder deshabilitado hasta que el endpoint de descarga exista
  /// (ver sección 11 del documento). Pasar `null` deja el botón inactivo.
  final VoidCallback? onUpdate;

  const ApproximateMatchBanner({
    super.key,
    required this.cultivo,
    required this.score,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.warmAmber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lgXl),
        border: Border.all(color: AppColors.warmAmber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 18,
                color: AppColors.warmAmber,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Resultado aproximado — actualiza el paquete de '
                  '$cultivo para mayor precisión',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // TODO: conectar con el endpoint de descarga cuando esté
              // disponible (ver sección 11 del documento de especificación).
              onPressed: onUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmAmber,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
              ),
              child: const Text('Actualizar ahora'),
            ),
          ),
        ],
      ),
    );
  }
}
