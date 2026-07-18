import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Encabezado del Perfil: avatar con iniciales, nombre y correo reales del
/// usuario autenticado (sin datos inventados como region o numero de parcelas).
class ProfileAvatarHeader extends StatelessWidget {
  final String initials;
  final String name;
  final String? email;

  const ProfileAvatarHeader({
    super.key,
    required this.initials,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.aPrimaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTypography.agendaTitle.copyWith(color: AppColors.aOnPrimary, fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            name,
            style: AppTypography.agendaTitle.copyWith(color: AppColors.aOnSurface),
          ),
          if (email != null && email!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              email!,
              style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
