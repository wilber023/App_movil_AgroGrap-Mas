import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Boton "+ Registrar otro cultivo".
class CultivoRegisterCta extends StatelessWidget {
  final VoidCallback onTap;
  const CultivoRegisterCta({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxlPlus,
        AppSpacing.xxlPlus,
        AppSpacing.xxlPlus,
        AppSpacing.none,
      ),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_circle_outline, color: AppColors.aSecondary, size: 20),
        label: Text(
          'Registrar otro cultivo',
          style: AppTypography.labelMd.copyWith(
            color: AppColors.aSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.aSecondary),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
        ),
      ),
    );
  }
}
