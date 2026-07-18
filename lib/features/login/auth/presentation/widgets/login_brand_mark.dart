import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Ícono de marca + títulos de [LoginPage]. El contenedor usa rounded
/// rectangle (16px) en lugar de círculo para un lenguaje geométrico más
/// arquitectónico.
class LoginBrandMark extends StatelessWidget {
  const LoginBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícono: rectángulo redondeado 16px — no píldora circular
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.forestGreen, AppColors.authBrandGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xlPlus),
            boxShadow: [
              BoxShadow(
                color: AppColors.forestGreen.withValues(alpha: 0.30),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.eco_rounded, color: AppColors.onPrimary, size: 26),
        ),
        const SizedBox(height: AppSpacing.xhugePlus),
        Text(
          'Inicia sesión',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.authFieldText,
            fontSize: 27,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.smMd),
        Text(
          'Accede a tus parcelas, diagnósticos y agenda.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.authInkMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
