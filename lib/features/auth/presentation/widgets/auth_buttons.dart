// =============================================================================
// Feature: Auth -- Widget: Botones de Acción Premium
// =============================================================================
// Botón primario: terracota quemada #CB6E44, radius 16px, plano (elevation 0).
// La sombra cálida la gestiona el widget padre en login_page para contexto.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Botón CTA principal. Terracota quemada, 52px, radio 16px.
class AuthPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const AuthPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  // Terracota quemada / arcilla sofisticada — cálido, orgánico, no fluorescente
  static const Color _terracota = Color(0xFFCB6E44);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _terracota,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _terracota.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white60,
          minimumSize: const Size.fromHeight(54),
          // Radio 16px consistente con inputs y resto de elementos
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    text,
                    style: AppTypography.labelMd.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Botón secundario outlined — Forest Green, 54px, radio 16px.
class AuthSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const AuthSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forestGreen,
          side: BorderSide(
            color: AppColors.forestGreen.withValues(alpha: 0.6),
            width: 1.5,
          ),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
