// =============================================================================
// AgroGraph-MAS — PackageMissingBanner (offline_knowledge)
// Ver agrograph_diagnostico_offline_embeddings.md, sección 7.1 (packageMissing).
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Banner gris para `DiagnosisSource.packageMissing`: no hay paquete offline
/// descargado para el cultivo detectado.
///
/// Reutiliza el mismo lenguaje visual del banner offline global
/// (`core/widgets/shared_components.dart`, ícono `cloud_off_outlined`,
/// `AppColors.offlineGreyDark`).
class PackageMissingBanner extends StatelessWidget {
  final String cultivo;

  /// Placeholder deshabilitado — la descarga real de paquetes no está en
  /// alcance de este sprint (ver sección 11 del documento). Pasar `null`
  /// deja el botón inactivo.
  final VoidCallback? onDownload;

  const PackageMissingBanner({
    super.key,
    required this.cultivo,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusOfflineBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.offlineGrey.withValues(alpha: 0.5)),
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
                color: AppColors.offlineGreyDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Descarga el paquete de $cultivo para ver el '
                  'tratamiento completo',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusOfflineText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              // TODO: conectar con el endpoint de descarga cuando esté
              // disponible (ver sección 11 del documento de especificación).
              onPressed: onDownload,
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Descargar paquete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.offlineGreyDark,
                side: const BorderSide(color: AppColors.offlineGrey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
