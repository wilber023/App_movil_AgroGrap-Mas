import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Contenedor con borde/fondo estandar usado por todas las listas de
/// opciones del Perfil (Mi cuenta, Recursos, Suscripcion, Legal).
class ProfileSettingsCard extends StatelessWidget {
  final List<Widget> children;
  const ProfileSettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      child: Column(children: children),
    );
  }
}
