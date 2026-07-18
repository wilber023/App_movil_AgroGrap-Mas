import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Foto analizada, con una pill "Ver imagen completa" que abre un visor a
/// pantalla completa (zoom con `InteractiveViewer`). Si no hay imagen
/// disponible, muestra un placeholder.
class DiagnosisResultPhotoCard extends StatelessWidget {
  final String? imagePath;

  const DiagnosisResultPhotoCard({super.key, required this.imagePath});

  bool get _hasImage => imagePath != null && File(imagePath!).existsSync();

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: AppColors.aOnSurface.withValues(alpha: 0.9),
        pageBuilder: (_, __, ___) => _FullscreenImageViewer(imagePath: imagePath!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xlPlus),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          _hasImage
              ? Image.file(File(imagePath!), height: 210, width: double.infinity, fit: BoxFit.cover)
              : Container(
                  height: 210,
                  width: double.infinity,
                  color: AppColors.aSurfaceContainerHigh,
                  child: const Center(
                    child: Icon(Icons.image_outlined, size: 56, color: AppColors.aOnSurfaceVariant),
                  ),
                ),
          if (_hasImage)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: GestureDetector(
                onTap: () => _openFullscreen(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.aOnPrimary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.open_in_full, size: 14, color: AppColors.aOnSurface),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Ver imagen completa',
                        style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurface, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FullscreenImageViewer extends StatelessWidget {
  final String imagePath;
  const _FullscreenImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(child: Image.file(File(imagePath))),
              ),
            ),
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.aOnPrimary, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
