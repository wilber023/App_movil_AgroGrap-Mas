import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Encabezado plano de "Registrar Cultivo": flecha atras + titulo + una
/// pequena ilustracion de brote compuesta con iconos (no se comparte con la
/// ilustracion de Mi Cultivo para no acoplar ambas pantallas).
class CultivoRegisterHeader extends StatelessWidget {
  const CultivoRegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xxlPlus,
        AppSpacing.none,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.aOnSurface),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              'Registrar tu cultivo',
              style: AppTypography.agendaTitle.copyWith(color: AppColors.aOnSurface),
            ),
          ),
          const _SproutBadge(),
        ],
      ),
    );
  }
}

class _SproutBadge extends StatelessWidget {
  const _SproutBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 34,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.aOnPrimaryFixedVariant,
              borderRadius: BorderRadius.circular(AppRadius.mdLg),
            ),
          ),
          const Positioned(
            bottom: 12,
            child: Icon(Icons.eco, color: AppColors.aSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}
