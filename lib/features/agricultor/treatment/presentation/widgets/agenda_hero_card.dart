import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'treatment_agenda_helpers.dart';

/// Tarjeta hero con gradiente al inicio de la Agenda Agronómica: fecha de
/// hoy, mensaje de estado y acceso a "Resumen semanal" (aún no implementado).
class AgendaHeroCard extends StatelessWidget {
  final bool allClear;
  const AgendaHeroCard({super.key, required this.allClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.huge, AppSpacing.huge, AppSpacing.huge, AppSpacing.huge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.forestGreen],
        ),
        borderRadius: BorderRadius.circular(AppRadius.huge),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ilustracion decorativa (hojas), semi-transparente, esquina superior derecha.
          Positioned(
            right: -18,
            top: -22,
            child: Icon(
              Icons.eco_rounded,
              size: 120,
              color: AppColors.white.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            right: 28,
            top: 6,
            child: Icon(
              Icons.eco_rounded,
              size: 46,
              color: AppColors.white.withValues(alpha: 0.16),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                todayLabel(),
                style: AppTypography.tituloMd.copyWith(
                  color: AppColors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxsPlus),
              Text(
                allClear
                    ? 'Sin pendientes urgentes. Buen trabajo.'
                    : 'Así va tu trabajo',
                style: AppTypography.etiquetaSm.copyWith(
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: AppSpacing.xxlPlus),
              GestureDetector(
                onTap: () => _showComingSoon(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Resumen semanal',
                        style: AppTypography.etiquetaSm.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('El resumen semanal estará disponible próximamente.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }
}
