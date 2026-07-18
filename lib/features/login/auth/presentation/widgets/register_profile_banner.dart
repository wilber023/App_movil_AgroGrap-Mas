import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/profile_type.dart';

/// Banner "Registrando como: X" de [RegisterPage], con color/icono según
/// el perfil seleccionado.
class RegisterProfileBanner extends StatelessWidget {
  const RegisterProfileBanner({super.key, required this.profileType});

  final ProfileType profileType;

  @override
  Widget build(BuildContext context) {
    final isAgricultor = profileType == ProfileType.agricultor;
    final color = isAgricultor ? AppColors.authAgricultorAccent : AppColors.warmAmber;
    final icon = isAgricultor ? Icons.agriculture_outlined : Icons.spa_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxlPlus,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lgXl),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Text(
              'Registrando como: ${profileType.displayName}',
              style: AppTypography.labelMd.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
