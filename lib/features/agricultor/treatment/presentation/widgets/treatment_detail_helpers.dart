import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/treatment_entity.dart';

// =============================================================================
// Helpers de formato y color (puramente visuales), compartidos por los
// widgets de TreatmentDetailPage. Se duplican deliberadamente respecto a
// treatment_agenda_helpers.dart (usado por treatment_page.dart) en vez de
// reutilizarlos: el umbral de "próximo" en [detailRelativeDayLabel] es de
// 30 días aquí vs. 7 días en la lista — unificar ambos cambiaría el
// comportamiento ya existente de una de las dos pantallas.
// =============================================================================

const _monthsShort = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

const _monthsLong = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String detailFmtShort(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]}';
String detailFmtLong(DateTime d) =>
    '${d.day} de ${_monthsLong[d.month - 1]} ${d.year}';

String detailRelativeDayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = target.difference(today).inDays;

  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  if (diff == -1) return 'Ayer';
  if (diff > 1) return diff <= 30 ? 'En $diff días' : detailFmtShort(date);
  return 'Hace ${-diff} días';
}

// Misma paleta de identidad que usa la lista (treatment_page.dart), para
// que cada tratamiento se vea con el mismo color/icono en ambas pantallas.
// Determinista por id: no es aleatorio, no se guarda nada nuevo. "Vencido"
// siempre prevalece porque es una señal de urgencia real.
const _agendaPalette = [
  AppColors.burntOrange,
  AppColors.forestGreen,
  AppColors.agendaIndigo,
  AppColors.infoBlue,
];

const _agendaIconPalette = [
  Icons.wb_sunny_rounded,
  Icons.eco_rounded,
  Icons.spa_rounded,
  Icons.water_drop_rounded,
];

Color detailAccentColor(TreatmentEntity t) {
  if (t.activeStep == null) return AppColors.forestGreen;
  if (t.isOverdue) return AppColors.error;
  return _agendaPalette[t.id.hashCode.abs() % _agendaPalette.length];
}

IconData detailCardIcon(TreatmentEntity t) {
  if (t.activeStep == null) return Icons.check_circle_outline_rounded;
  if (t.isOverdue) return Icons.error_outline_rounded;
  return _agendaIconPalette[t.id.hashCode.abs() % _agendaIconPalette.length];
}

String detailHeaderStatusLabel(TreatmentEntity t) {
  if (t.activeStep == null) return 'Completo';
  if (t.isOverdue) return 'Vencido';
  return 'En curso';
}
