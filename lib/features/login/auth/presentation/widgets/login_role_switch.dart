import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Selector de rol "Tab Switch" integrado de [LoginPage]. El contenedor se
/// fusiona con el fondo superior del degradado. Seleccionado = relieve
/// blanco almendra suave + micro-sombra; no seleccionado = transparente,
/// solo tipografía.
class LoginRoleSwitch extends StatelessWidget {
  const LoginRoleSwitch({super.key, required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        // Color que se funde con el degradado eucalipto del fondo
        color: AppColors.authRoleSwitchBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          _buildRoleTab(context, 'Agricultor', 0),
          const SizedBox(width: AppSpacing.xs),
          _buildRoleTab(context, 'Aprendiz', 1),
        ],
      ),
    );
  }

  Widget _buildRoleTab(BuildContext context, String label, int index) {
    final isSelected = index == selectedIndex;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lgXl),
          decoration: BoxDecoration(
            // Seleccionado: hueso almendra = mismo tono del fondo inferior
            color: isSelected ? AppColors.authBgBottom : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.authFieldText.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelMd.copyWith(
              color: isSelected ? AppColors.authFieldText : AppColors.authInkMuted,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
