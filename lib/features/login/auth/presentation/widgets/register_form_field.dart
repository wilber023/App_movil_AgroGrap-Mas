import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'auth_text_field.dart';

/// Campo de formulario de [RegisterPage] con etiqueta de error opcional
/// debajo. Cubre tanto campos de texto simples como de contraseña
/// (pasando [obscureText]/[onToggleObscure]) para no duplicar el wrapper.
class RegisterFormField extends StatelessWidget {
  const RegisterFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.errorText,
    this.textInputAction = TextInputAction.next,
    this.obscureText,
    this.onToggleObscure,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final String? errorText;
  final TextInputAction textInputAction;

  /// Si no es null, el campo se comporta como contraseña: el icono de
  /// alternar visibilidad aparece como `suffixIcon`.
  final bool? obscureText;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final isPassword = obscureText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTextField(
          controller: controller,
          label: label,
          hintText: hintText,
          prefixIcon: prefixIcon,
          obscureText: obscureText ?? false,
          textInputAction: textInputAction,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText! ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.authMutedSage,
                    size: 22,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          validator: (_) => null, // Validation done manually
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xxlPlus),
            child: Text(
              errorText!,
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
