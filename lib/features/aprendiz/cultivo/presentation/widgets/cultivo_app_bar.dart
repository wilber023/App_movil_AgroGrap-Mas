import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Barra superior de Mi Cultivo: menu, marca "AgroGraph IA" y notificaciones.
///
/// Los botones son marcadores visuales sin accion, igual que el resto de la
/// barra superior de Aprendiz, hasta que el proyecto incorpore un
/// drawer/centro de notificaciones real.
class CultivoAppBar extends StatelessWidget {
  const CultivoAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.aPrimaryContainer,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.aOnPrimary),
            onPressed: () {},
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.eco, color: AppColors.aOnPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AgroGraph IA',
                  style: AppTypography.agendaTitle.copyWith(color: AppColors.aOnPrimary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.aOnPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
