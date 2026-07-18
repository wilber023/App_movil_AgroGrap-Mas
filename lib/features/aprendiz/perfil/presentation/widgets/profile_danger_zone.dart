import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Zona de peligro: cerrar sesion / eliminar cuenta, con una diferenciacion
/// visual clara (borde y textos en color de error) respecto al resto del
/// contenido del Perfil.
class ProfileDangerZone extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const ProfileDangerZone({super.key, required this.onLogout, required this.onDeleteAccount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ZONA DE PELIGRO',
          style: AppTypography.statusPill.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.aSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.lgXl),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: onLogout,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lgXl)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxlPlus,
                    vertical: AppSpacing.xxl,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: AppColors.error, size: 22),
                      const SizedBox(width: AppSpacing.xxl),
                      Text(
                        'Cerrar sesión',
                        style: AppTypography.agendaBody.copyWith(
                          fontSize: 15,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, thickness: 1, indent: AppSpacing.xxgiant, color: AppColors.error.withValues(alpha: 0.2)),
              InkWell(
                onTap: onDeleteAccount,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.lgXl)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxlPlus,
                    vertical: AppSpacing.xxl,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
                      const SizedBox(width: AppSpacing.xxl),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Eliminar mi cuenta',
                              style: AppTypography.agendaBody.copyWith(
                                fontSize: 15,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Esta acción es permanente e irreversible',
                              style: AppTypography.etiquetaSm.copyWith(
                                color: AppColors.error.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
