import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../widgets/auth_buttons.dart';

/// Link plano "¿Olvidaste tu contraseña?" de [LoginPage] — sin `TextButton`
/// ni contenedor, texto oscuro, sin decoración. Aún no implementado (el
/// `onTap` original es un no-op).
class LoginForgotPasswordLink extends StatelessWidget {
  const LoginForgotPasswordLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text(
            '¿Olvidaste tu contraseña?',
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.authInkMuted,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón terracota con sombra cálida de [LoginPage] — el calor visual del
/// CTA contrasta suavemente con el fondo verde-neutro de la pantalla.
class LoginButton extends StatelessWidget {
  const LoginButton({super.key, required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        boxShadow: isLoading
            ? []
            : [
                BoxShadow(
                  color: AppColors.authTerracota.withValues(alpha: 0.30),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: AuthPrimaryButton(
        text: 'Iniciar sesión',
        icon: Icons.login_rounded,
        isLoading: isLoading,
        onPressed: onPressed,
      ),
    );
  }
}

/// Divisor orgánico de [LoginPage] — sin contenedor para el "o", solo
/// tipografía flotante.
class LoginDivider extends StatelessWidget {
  const LoginDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.authDivider,
            thickness: 0.7,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
          child: Text(
            'o',
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.authInkMuted,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.authDivider,
            thickness: 0.7,
          ),
        ),
      ],
    );
  }
}

/// Link de registro de [LoginPage] — texto plano, perfectamente alineado a
/// la rejilla.
class LoginRegisterLink extends StatelessWidget {
  const LoginRegisterLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: RichText(
            text: TextSpan(
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.authInkMuted,
                fontSize: 13,
              ),
              children: [
                const TextSpan(text: '¿No tienes cuenta?  '),
                TextSpan(
                  text: 'Crear cuenta',
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
      ),
    );
  }
}
