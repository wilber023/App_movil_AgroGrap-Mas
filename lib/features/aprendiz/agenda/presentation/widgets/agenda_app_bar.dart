import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Barra superior de Agenda: menu, titulo centrado y filtro.
///
/// Los botones de menu/filtro son marcadores visuales sin accion, igual que
/// el resto de la barra superior de Aprendiz (ver `aprendiz_home_page.dart`)
/// hasta que el proyecto incorpore un drawer/filtro real.
class AgendaAppBar extends StatelessWidget {
  const AgendaAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.aMint,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.aOnSurface),
            onPressed: () {},
          ),
          Expanded(
            child: Text(
              'Agenda',
              textAlign: TextAlign.center,
              style: AppTypography.agendaTitle.copyWith(color: AppColors.aOnSurface),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.aOnSurface),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
