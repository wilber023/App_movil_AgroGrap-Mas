import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/profile_type.dart';

/// Toasts y diálogo de retroalimentación de [RegisterPage] (éxito, error,
/// "próximamente"). Funciones puras de presentación: no leen ni modifican
/// estado, solo muestran lo que la página ya decidió.

void showRegisterSuccessToast(BuildContext context, String fullName) {
  final firstName = fullName.split(' ').first;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.onPrimary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.onPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.xxl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¡Bienvenido, $firstName!',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Cuenta creada exitosamente.',
                    style: AppTypography.etiquetaSm.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxlPlus,
          vertical: AppSpacing.xl,
        ),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
}

void showRegisterErrorToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.onPrimary, size: 22),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                message,
                style: AppTypography.labelMd.copyWith(color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxlPlus,
          vertical: AppSpacing.xl,
        ),
        duration: const Duration(seconds: 4),
        elevation: 6,
      ),
    );
}

void showRegisterComingSoonDialog(BuildContext context, ProfileType profileType) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xlPlus)),
      title: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warmAmber),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Próximamente',
            style: AppTypography.headlineMd.copyWith(fontSize: 18),
          ),
        ],
      ),
      content: Text(
        'El perfil ${profileType.displayName} estará disponible muy pronto. Estamos preparando tu experiencia guiada.',
        style: AppTypography.bodyMd,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
          },
          child: Text(
            'Entendido',
            style: AppTypography.labelMd.copyWith(color: AppColors.forestGreen),
          ),
        ),
      ],
    ),
  );
}
