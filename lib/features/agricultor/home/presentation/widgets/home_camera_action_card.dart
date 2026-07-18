import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../diagnosis/presentation/pages/diagnosis_page.dart';

/// Tarjeta de escaneo principal de HomePage: acceso directo a la cámara de
/// diagnóstico, con ilustración decorativa.
class HomeCameraActionCard extends StatelessWidget {
  const HomeCameraActionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.huge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xhuge),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // Row + Expanded (no Stack/Positioned): el texto/boton tiene prioridad
      // sobre el ancho disponible y la ilustracion (96px fijos) nunca puede
      // solaparse con ellos — si la pantalla es angosta, el titulo envuelve
      // a 2 lineas (la tarjeta crece) en vez de superponerse.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.onPrimary, size: 26),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  'Escanear cultivo',
                  style: AppTypography.tituloLg.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  // Etiqueta breve — reemplaza "Diagnóstico IA en segundos" a pedido.
                  'Detecta enfermedades al instante',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DiagnosisPage()),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.primary),
                    label: Text(
                      'Tomar fotografía',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          const _ScanFrameIllustration(),
        ],
      ),
    );
  }
}

/// Ilustracion decorativa (marco de escaneo) para la tarjeta de camara.
/// Construida con widgets planos, sin assets de imagen.
class _ScanFrameIllustration extends StatelessWidget {
  const _ScanFrameIllustration();

  @override
  Widget build(BuildContext context) {
    const c = AppColors.white70;
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.eco_rounded, size: 52, color: c),
          Container(
            width: 64,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.homeScanAccent,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              boxShadow: [
                BoxShadow(color: AppColors.homeScanAccent.withValues(alpha: 0.6), blurRadius: 6),
              ],
            ),
          ),
          Positioned(top: 0, left: 0, child: _corner(top: true, left: true)),
          Positioned(top: 0, right: 0, child: _corner(top: true, left: false)),
          Positioned(bottom: 0, left: 0, child: _corner(top: false, left: true)),
          Positioned(bottom: 0, right: 0, child: _corner(top: false, left: false)),
        ],
      ),
    );
  }

  Widget _corner({required bool top, required bool left}) {
    const side = BorderSide(color: AppColors.white70, width: 2.5);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: !top ? side : BorderSide.none,
          left: left ? side : BorderSide.none,
          right: !left ? side : BorderSide.none,
        ),
      ),
    );
  }
}
