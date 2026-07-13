import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/alerta_epidemiologica_entity.dart';
import '../pages/epidemiological_map_page.dart';

/// Banner de alerta epidemiológica para el Home. No se renderiza nada si
/// [alerta] es `null` (sin alerta para el estado del usuario) -- nunca
/// fuerza contenido vacío.
class EpidemiologicalAlertBanner extends StatelessWidget {
  final AlertaEpidemiologicaEntity? alerta;

  const EpidemiologicalAlertBanner({super.key, this.alerta});

  @override
  Widget build(BuildContext context) {
    final alerta = this.alerta;
    if (alerta == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ALERTA EPIDEMIOLÓGICA · ${alerta.estado}',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alerta.mensaje,
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, EpidemiologicalMapPage.route()),
              icon: const Icon(Icons.map_outlined, size: 17),
              label: const Text('Ver mapa de alertas'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
