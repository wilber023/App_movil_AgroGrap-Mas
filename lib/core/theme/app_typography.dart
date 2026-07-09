// =============================================================================
// AgroGraph-MAS -- Tipografia Centralizada
// =============================================================================
// Fuente: Stitch Project 9941199551312199248
//   DS 1: "AgroGraph-MAS Design System" (assets/41072a0a637a442f8a6c4c9c80d66e6f)
//   DS 2: "AgroGraph-MAS"               (assets/70fd5a4b76954b418550ed0d62419eea)
//
// Font: Inter (exclusivo). Todos los text styles del proyecto deben
// consumirse desde esta clase.
//
// Se usa el paquete `google_fonts` (ya declarado en pubspec.yaml) para
// cargar la tipografia real: antes, `fontFamily: 'Inter'` apuntaba a una
// fuente nunca empaquetada como asset, asi que el motor de renderizado
// caia en silencio a la fuente por defecto del sistema del telefono. Cada
// llamada a GoogleFonts.inter(...) descarga (una sola vez, con cache local
// para uso posterior offline) el archivo real del peso solicitado.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens tipograficos del Design System de AgroGraph-MAS.
///
/// Basado en la fuente Inter con escalas adaptadas para legibilidad
/// en entornos rurales con alta luminosidad.
abstract final class AppTypography {
  AppTypography._();

  // ---------------------------------------------------------------------------
  // DS 1 -- Escala tipografica principal
  // ---------------------------------------------------------------------------

  /// Titulo de enfermedad -- Peso maximo, tracking cerrado.
  static final TextStyle displayDisease = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25, // lineHeight 40px / fontSize 32px
    letterSpacing: -0.64, // -0.02em * 32
  );

  /// Titulo de enfermedad (mobile) -- Variante reducida.
  static final TextStyle displayDiseaseMobile = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.286, // 36px / 28px
  );

  /// Headline medium -- Subtitulos y secciones.
  static final TextStyle headlineMd = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.333, // 32px / 24px
  );

  /// Body large -- Texto de lectura principal ampliado.
  static final TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.556, // 28px / 18px
  );

  /// Body medium -- Texto de lectura estandar (minimo 16px).
  static final TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5, // 24px / 16px
  );

  /// Label medium -- Etiquetas de campos y botones.
  static final TextStyle labelMd = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.429, // 20px / 14px
    letterSpacing: 0.14, // 0.01em * 14
  );

  /// Status pill -- Texto de pills de estado (Saludable, En Riesgo).
  static final TextStyle statusPill = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.455, // 16px / 11px
    letterSpacing: 0.33, // 0.03em * 11
  );

  // ---------------------------------------------------------------------------
  // DS 2 -- Escala tipografica alternativa (nomenclatura en espanol)
  // ---------------------------------------------------------------------------

  /// Titulo XL -- Solo para pantallas de alto impacto.
  static final TextStyle tituloXl = GoogleFonts.inter(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2, // 48px / 40px
    letterSpacing: -0.8, // -0.02em * 40
  );

  /// Titulo LG -- Encabezados principales.
  static final TextStyle tituloLg = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25, // 40px / 32px
    letterSpacing: -0.32, // -0.01em * 32
  );

  /// Titulo LG Mobile -- Variante mobile.
  static final TextStyle tituloLgMobile = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.214, // 34px / 28px
  );

  /// Titulo MD -- Subtitulos de seccion.
  static final TextStyle tituloMd = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.333, // 32px / 24px
  );

  /// Etiqueta bold -- Labels destacados en formularios.
  static final TextStyle etiquetaBold = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.429, // 20px / 14px
  );

  /// Etiqueta small -- Texto auxiliar y captions.
  static final TextStyle etiquetaSm = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.333, // 16px / 12px
  );

  // ---------------------------------------------------------------------------
  // APRENDIZ / AGENDA -- Tokens puntuales del rediseño de Agenda
  // ---------------------------------------------------------------------------

  /// Titulo principal de Agenda (app bar "Agenda" y titulo de la etapa del dia).
  static final TextStyle agendaTitle = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// Titulo de seccion dentro de Agenda (ej. "Proximas tareas").
  static final TextStyle agendaSectionTitle = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// Texto de cuerpo de Agenda (descripciones, checklist, tarjetas de tareas).
  static final TextStyle agendaBody = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  /// Subtitulo compacto de Agenda (mes del calendario, nombre del cultivo).
  static final TextStyle agendaSubtitle = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
}
