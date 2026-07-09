import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Barra superior de Perfil: menu, titulo y acceso a configuracion.
/// Mismo estilo que el resto de las pantallas de Aprendiz.
class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.aPrimaryContainer,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.menu, color: AppColors.aOnPrimary), onPressed: () {}),
          Expanded(
            child: Text(
              'Perfil',
              textAlign: TextAlign.center,
              style: AppTypography.agendaTitle.copyWith(color: AppColors.aOnPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.aOnPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
