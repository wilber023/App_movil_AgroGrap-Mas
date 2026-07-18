import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'diagnosis_camera_controls.dart';

/// Barra de disparo inicial de [DiagnosisPage]: historial / cámara /
/// galería.
class DiagnosisShootingBar extends StatelessWidget {
  const DiagnosisShootingBar({
    super.key,
    required this.isCapturing,
    required this.onHistory,
    required this.onShutter,
    required this.onGallery,
  });

  final bool isCapturing;
  final VoidCallback onHistory;
  final VoidCallback onShutter;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      color: AppColors.black.withValues(alpha: 0.6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          DiagnosisIconButton(
            icon: Icons.access_time_outlined,
            label: 'Historial',
            onTap: onHistory,
          ),
          DiagnosisShutterButton(isCapturing: isCapturing, onTap: onShutter),
          DiagnosisIconButton(
            icon: Icons.photo_outlined,
            label: 'Galería',
            onTap: onGallery,
          ),
        ],
      ),
    );
  }
}
