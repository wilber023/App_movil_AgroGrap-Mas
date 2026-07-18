import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

// =============================================================================
// Helpers puramente de presentacion, compartidos por los widgets de
// HomePage. No agregan ningun dato nuevo: solo formatean o clasifican
// visualmente datos que ya exponen HomeBloc, ParcelBloc y TreatmentBloc.
// =============================================================================

String homeGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Buenos días';
  if (hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

String homeFirstName(String fullName) =>
    fullName.trim().isEmpty ? '' : fullName.trim().split(' ').first;

String homeTimeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 1) {
    return 'hace ${diff.inDays} día${diff.inDays == 1 ? '' : 's'}';
  }
  if (diff.inHours >= 1) return 'hace ${diff.inHours} h';
  if (diff.inMinutes >= 1) return 'hace ${diff.inMinutes} min';
  return 'hace un momento';
}

/// Relabel puramente visual del status ya almacenado en ParcelEntity.status
/// ('Alerta' | 'Seguimiento' | 'Saludable' | 'Sin diagnostico'). No cambia
/// el dato guardado, solo como se muestra.
({String label, Color color}) homeParcelStatusInfo(String status) {
  switch (status) {
    case 'Alerta':
      return (label: 'Riesgo alto', color: AppColors.error);
    case 'Seguimiento':
      return (label: 'Atención', color: AppColors.burntOrange);
    case 'Saludable':
      return (label: 'Saludable', color: AppColors.forestGreen);
    default:
      return (label: 'Sin diagnóstico', color: AppColors.onSurfaceVariant);
  }
}

/// No existe un porcentaje de salud medido en el dominio (ParcelEntity no
/// tiene ese campo). Este numero es una representacion visual estilizada
/// del status ya conocido, no una metrica precisa — por eso el anillo se
/// etiqueta "Estado del cultivo" y no "Salud medida".
int? homeParcelStatusTier(String status) {
  switch (status) {
    case 'Saludable':
      return 92;
    case 'Seguimiento':
      return 60;
    case 'Alerta':
      return 30;
    default:
      return null; // Sin diagnostico: no se inventa un numero.
  }
}

IconData homeCropIcon(String cropName) {
  final name = cropName.toLowerCase();
  if (name.contains('tomate')) return Icons.local_pizza_outlined;
  if (name.contains('papa')) return Icons.egg_outlined;
  if (name.contains('maíz') || name.contains('maiz')) return Icons.grass_outlined;
  if (name.contains('pepino')) return Icons.eco_outlined;
  if (name.contains('calabaza')) return Icons.circle_outlined;
  if (name.contains('pimiento') || name.contains('chile')) return Icons.local_fire_department_outlined;
  if (name.contains('fresa')) return Icons.favorite_border_rounded;
  return Icons.eco_outlined;
}
