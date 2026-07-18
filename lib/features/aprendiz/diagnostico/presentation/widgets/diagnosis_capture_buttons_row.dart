import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Fila de botones "Tomar foto" / "Galería" de [DiagnosisEntryAprendizPage].
class DiagnosisCaptureButtonsRow extends StatelessWidget {
  const DiagnosisCaptureButtonsRow({
    super.key,
    required this.isEnabled,
    required this.onTakePhoto,
    required this.onPickGallery,
  });

  final bool isEnabled;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickGallery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isEnabled ? onTakePhoto : null,
            icon: const Icon(Icons.photo_camera_outlined, color: AppColors.aOnPrimary, size: 20),
            label: Text(
              'Tomar foto',
              style: AppTypography.labelMd.copyWith(color: AppColors.aOnPrimary, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.aSecondary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isEnabled ? onPickGallery : null,
            icon: const Icon(Icons.image_outlined, color: AppColors.aSecondary, size: 20),
            label: Text(
              'Galería',
              style: AppTypography.labelMd.copyWith(color: AppColors.aSecondary, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.aSecondary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
            ),
          ),
        ),
      ],
    );
  }
}
