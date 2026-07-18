import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Encabezado de saludo de Mi Cultivo: "Hola, aprendiz" + subtitulo, con una
/// pequena ilustracion decorativa (sol + brote) compuesta con iconos, ya que
/// el proyecto no cuenta con assets de ilustracion para esta pantalla.
class CultivoGreetingHeader extends StatelessWidget {
  const CultivoGreetingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxlPlus,
        AppSpacing.huge,
        AppSpacing.xxlPlus,
        AppSpacing.none,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '¡Hola, aprendiz!',
                      style: AppTypography.agendaTitle.copyWith(color: AppColors.aPrimary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.eco, color: AppColors.aSecondary, size: 20),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tu guía inteligente para aprender a cultivar.',
                  style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          const _SunSproutIllustration(),
        ],
      ),
    );
  }
}

class _SunSproutIllustration extends StatelessWidget {
  const _SunSproutIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          const Positioned(
            top: 0,
            right: 0,
            child: Icon(Icons.wb_sunny, color: AppColors.aOrange, size: 26),
          ),
          Container(
            width: 44,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.aOnPrimaryFixedVariant,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
          const Positioned(
            bottom: 18,
            child: Icon(Icons.eco, color: AppColors.aSecondary, size: 22),
          ),
        ],
      ),
    );
  }
}
