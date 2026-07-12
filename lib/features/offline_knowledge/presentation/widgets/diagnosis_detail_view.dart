// =============================================================================
// AgroGraph-MAS — DiagnosisDetailView (offline_knowledge)
// Renderiza DiagnosisDetail según su `source`, ver sección 7.1 del documento.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared_components.dart';
import '../../domain/entities/diagnosis_detail.dart';
import 'approximate_match_banner.dart';
import 'package_missing_banner.dart';

class DiagnosisDetailView extends StatelessWidget {
  final DiagnosisDetail detail;

  const DiagnosisDetailView({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return switch (detail) {
      DiagnosisDetailExact() => _FichaCard(detail: detail),
      DiagnosisDetailApproximate d => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ApproximateMatchBanner(cultivo: d.ficha.cultivo, score: d.score),
          const SizedBox(height: 12),
          _FichaCard(detail: detail),
        ],
      ),
      DiagnosisDetailNotFound() => const OfflineBanner(
        message:
            'No se encontró información offline para esta '
            'enfermedad. Se mostrará al recuperar conexión.',
      ),
      DiagnosisDetailPackageMissing d => PackageMissingBanner(
        cultivo: d.cultivo,
      ),
    };
  }
}

/// Ficha completa (enfermedad, síntomas, tratamiento, severidad).
///
/// Usada tanto para `exactMatch` (sin advertencia, tono normal) como para
/// `semanticFallback` (precedida por [ApproximateMatchBanner]).
class _FichaCard extends StatelessWidget {
  final DiagnosisDetail detail;

  const _FichaCard({required this.detail});

  /// Mapea la severidad textual de la ficha al sistema de colores de estado
  /// de salud ya definido en AppColors (sección 7.1: verde saludable, ámbar
  /// seguimiento, terracota alerta). No especificado literalmente en el
  /// documento — decisión documentada en offline_knowledge_implementacion.md.
  Color _severidadColor(String severidad) {
    final s = severidad.toLowerCase();
    if (s.contains('alta') || s.contains('severa') || s.contains('grave')) {
      return AppColors.burntOrange;
    }
    if (s.contains('media') || s.contains('moderada')) {
      return AppColors.warmAmber;
    }
    return AppColors.forestGreen;
  }

  @override
  Widget build(BuildContext context) {
    final severidadColor = _severidadColor(detail.severidad);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.enfermedad,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              if (detail.severidad.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: severidadColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    detail.severidad,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: severidadColor,
                    ),
                  ),
                ),
            ],
          ),
          if (detail.sintomas.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Síntomas',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail.sintomas,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.onSurface,
                height: 1.5,
              ),
            ),
          ],
          if (detail.tratamiento.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Tratamiento',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail.tratamiento,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.onSurface,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
