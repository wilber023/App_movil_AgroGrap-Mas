import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Etiqueta de seccion reutilizada por Mi cuenta, Recursos, Suscripcion y
/// Legal ("MI CUENTA", "RECURSOS", etc.).
class ProfileSectionHeader extends StatelessWidget {
  final String label;
  const ProfileSectionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.statusPill.copyWith(
        color: AppColors.aOnSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
      ),
    );
  }
}
