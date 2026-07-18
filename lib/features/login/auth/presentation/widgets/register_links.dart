import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/profile_type.dart';

/// Enlace "¿Eres un principiante? / ¿Ya tienes experiencia?" para cambiar
/// entre perfiles Agricultor/Aprendiz en [RegisterPage].
class RegisterCrossProfileLink extends StatelessWidget {
  const RegisterCrossProfileLink({
    super.key,
    required this.profileType,
    required this.onSwitch,
  });

  final ProfileType profileType;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final isAgricultor = profileType == ProfileType.agricultor;
    final text1 = isAgricultor ? '¿Eres un principiante? ' : '¿Ya tienes experiencia? ';
    final text2 = isAgricultor ? 'Cambiar a Aprendiz Agrícola' : 'Cambiar a Agricultor';

    return Center(
      child: GestureDetector(
        onTap: onSwitch,
        child: RichText(
          text: TextSpan(
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.authMutedSage,
              fontSize: 13,
            ),
            children: [
              TextSpan(text: text1),
              TextSpan(
                text: text2,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.forestGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Separador "o" entre el formulario y el enlace de inicio de sesión.
class RegisterDivider extends StatelessWidget {
  const RegisterDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 0.5, color: AppColors.cardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
          child: Text(
            'o',
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.authMutedSage),
          ),
        ),
        Expanded(child: Container(height: 0.5, color: AppColors.cardBorder)),
      ],
    );
  }
}

/// Enlace "¿Ya tienes cuenta? Iniciar sesión" de [RegisterPage].
class RegisterLoginLink extends StatelessWidget {
  const RegisterLoginLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.authMutedSage,
              fontSize: 13,
            ),
            children: [
              const TextSpan(text: '¿Ya tienes cuenta? '),
              TextSpan(
                text: 'Iniciar sesión',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.forestGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
