import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Botón "ojo" para mostrar/ocultar la contraseña en [LoginPage] — icono de
/// trazo fino, gris piedra.
class LoginToggleEyeButton extends StatelessWidget {
  final bool obscured;
  final VoidCallback onTap;

  const LoginToggleEyeButton({super.key, required this.obscured, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.authFieldIcon,
        size: 20,
      ),
      onPressed: onTap,
    );
  }
}
