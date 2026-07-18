import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Encabezado estático de [RegisterPage]: icono, título y subtítulo.
class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: AppColors.forestGreen,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.huge),
        Text(
          'Crea tu cuenta',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.authHeaderTitle,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tus datos se guardan de forma segura localmente.',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.authMutedSage,
          ),
        ),
      ],
    );
  }
}
