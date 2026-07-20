import 'package:flutter/material.dart';

/// Datos de una sección del diagnóstico presentada como tarjeta resumen en
/// [DiagnosisSectionCarousel]. Cada sección se expande a una experiencia
/// inmersiva mostrando el contenido que produce `expandedBuilder` — el
/// carrusel nunca conoce el contenido real, solo lo delega.
class DiagnosisSectionItem {
  final String id;
  final IconData icon;
  final Color accent;
  final Color background;
  final Color border;
  final String title;
  final String summary;
  final WidgetBuilder expandedBuilder;

  const DiagnosisSectionItem({
    required this.id,
    required this.icon,
    required this.accent,
    required this.background,
    required this.border,
    required this.title,
    required this.summary,
    required this.expandedBuilder,
  });
}
