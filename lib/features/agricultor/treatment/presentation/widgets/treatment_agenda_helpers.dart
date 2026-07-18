import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/treatment_entity.dart';

// =============================================================================
// Helpers de formato y de presentacion (puramente visuales), compartidos por
// los widgets de la Agenda Agronómica (TreatmentPage y su árbol de tarjetas).
// No contienen reglas de negocio: solo formatean o mapean a color/icono
// datos que la entidad ya expone (isOverdue, isDueToday, isDueThisWeek,
// activeStep, daysOverdue). La logica de filtros/estados vive intacta en
// TreatmentEntity/TreatmentBloc.
// =============================================================================

const treatmentMonthsShort = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

const treatmentMonthsLong = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String fmtShortDate(DateTime d) => '${d.day} ${treatmentMonthsShort[d.month - 1]}';

String todayLabel() {
  final now = DateTime.now();
  return 'Hoy, ${now.day} de ${treatmentMonthsLong[now.month - 1]}';
}

/// Etiqueta relativa ("Hoy", "Mañana", "En 3 días", "Hace 2 días") a partir
/// de una fecha que el dominio ya calculo. Solo formatea, no decide nada.
String relativeDayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = target.difference(today).inDays;

  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  if (diff == -1) return 'Ayer';
  if (diff > 1) return diff <= 7 ? 'En $diff días' : fmtShortDate(date);
  return 'Hace ${-diff} días';
}

/// Paleta de identidad decorativa por tarjeta (variedad visual, no urgencia).
/// El color/icono de cada tratamiento se elige de forma determinista segun
/// su id, para que sea siempre el mismo entre recargas y entre la lista y
/// el detalle — no es aleatorio, no se guarda nada nuevo.
const agendaPalette = [
  AppColors.burntOrange,
  AppColors.forestGreen,
  AppColors.agendaIndigo,
  AppColors.infoBlue,
];

const agendaIconPalette = [
  Icons.wb_sunny_rounded,
  Icons.eco_rounded,
  Icons.spa_rounded,
  Icons.water_drop_rounded,
];

/// Color de identidad de la tarjeta. "Vencido" y "Completo" siempre
/// prevalecen sobre la decoracion porque son señales de urgencia reales
/// que no deben perderse por variedad visual.
Color agendaAccentColor(TreatmentEntity t) {
  if (t.activeStep == null) return AppColors.forestGreen;
  if (t.isOverdue) return AppColors.error;
  return agendaPalette[t.id.hashCode.abs() % agendaPalette.length];
}

IconData agendaCardIcon(TreatmentEntity t) {
  if (t.activeStep == null) return Icons.check_circle_outline_rounded;
  if (t.isOverdue) return Icons.error_outline_rounded;
  return agendaIconPalette[t.id.hashCode.abs() % agendaIconPalette.length];
}

/// Texto corto de la badge de la tarjeta: "Completo", "Vencido hace X días"
/// o la etiqueta relativa del proximo paso.
String cardBadgeLabel(TreatmentEntity t) {
  if (t.activeStep == null) return 'Completo';
  final step = t.activeStep!;
  if (t.isOverdue) {
    final days = step.daysOverdue;
    return 'Vencido hace $days día${days == 1 ? '' : 's'}';
  }
  return relativeDayLabel(step.scheduledDate);
}

enum AgendaFilter { todos, hoy, semana, vencidos }

// Agrupacion visual usada unicamente en el filtro "Todos" (Etapa 4). No es
// un calendario ni una pantalla nueva: es la misma lista, organizada en
// secciones con encabezado.
enum AgendaSection { vencidos, hoy, semana, masAdelante, completados }

const agendaSectionOrder = [
  AgendaSection.vencidos,
  AgendaSection.hoy,
  AgendaSection.semana,
  AgendaSection.masAdelante,
  AgendaSection.completados,
];

const agendaSectionTitles = {
  AgendaSection.vencidos: 'Vencidos',
  AgendaSection.hoy: 'Hoy',
  AgendaSection.semana: 'Esta semana',
  AgendaSection.masAdelante: 'Más adelante',
  AgendaSection.completados: 'Completados',
};

AgendaSection sectionFor(TreatmentEntity t) {
  if (t.activeStep == null) return AgendaSection.completados;
  if (t.isOverdue) return AgendaSection.vencidos;
  if (t.isDueToday) return AgendaSection.hoy;
  if (t.isDueThisWeek) return AgendaSection.semana;
  return AgendaSection.masAdelante;
}

Color sectionColor(AgendaSection section) {
  switch (section) {
    case AgendaSection.vencidos:
      return AppColors.error;
    case AgendaSection.hoy:
      return AppColors.burntOrange;
    case AgendaSection.semana:
      return AppColors.warmAmber;
    case AgendaSection.masAdelante:
      return AppColors.outline;
    case AgendaSection.completados:
      return AppColors.forestGreen;
  }
}

IconData sectionIcon(AgendaSection section) {
  switch (section) {
    case AgendaSection.vencidos:
      return Icons.error_outline_rounded;
    case AgendaSection.hoy:
      return Icons.today_rounded;
    case AgendaSection.semana:
      return Icons.date_range_rounded;
    case AgendaSection.masAdelante:
      return Icons.schedule_rounded;
    case AgendaSection.completados:
      return Icons.check_circle_outline_rounded;
  }
}

/// Umbral de caracteres para mostrar el toggle "Ver más/Ver menos" en la
/// descripción de un paso del timeline.
const descriptionCollapseThreshold = 90;
