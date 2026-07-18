import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/profile_type.dart';

/// Toast de error y diálogo "próximamente" de [LoginPage]. Funciones puras
/// de presentación: no leen ni modifican estado.

void showLoginErrorToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.onPrimary, size: 20),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(message,
                style: AppTypography.labelMd.copyWith(
                    color: AppColors.onPrimary, fontSize: 13)),
          ),
        ]),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.xl),
        duration: const Duration(seconds: 4),
        elevation: 0,
      ),
    );
}

void showLoginComingSoonDialog(BuildContext context, ProfileType profileType) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.authBgBottom,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxlPlus)),
      title: Row(children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.warmAmber),
        const SizedBox(width: AppSpacing.md),
        Text('Próximamente',
            style: AppTypography.headlineMd.copyWith(fontSize: 18)),
      ]),
      content: Text(
        'El perfil ${profileType.displayName} estará disponible muy pronto.',
        style: AppTypography.bodyMd.copyWith(color: AppColors.authInkMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('Entendido',
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.forestGreen)),
        ),
      ],
    ),
  );
}
