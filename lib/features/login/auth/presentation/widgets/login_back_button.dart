import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Botón de retroceso circular translúcido de [LoginPage] — convención de
/// navegación móvil.
class LoginBackButton extends StatelessWidget {
  const LoginBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.75),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_rounded,
            color: AppColors.onSurface, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
