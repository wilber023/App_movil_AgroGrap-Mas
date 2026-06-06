// =============================================================================
// AgroGraph-MAS -- Tipografia Centralizada
// =============================================================================
// Fuente: Stitch Project 9941199551312199248
//   DS 1: "AgroGraph-MAS Design System" (assets/41072a0a637a442f8a6c4c9c80d66e6f)
//   DS 2: "AgroGraph-MAS"               (assets/70fd5a4b76954b418550ed0d62419eea)
//
// Font: Inter (exclusivo). Todos los text styles del proyecto deben
// consumirse desde esta clase.
// =============================================================================

import 'package:flutter/material.dart';

/// Tokens tipograficos del Design System de AgroGraph-MAS.
///
/// Basado en la fuente Inter con escalas adaptadas para legibilidad
/// en entornos rurales con alta luminosidad.
abstract final class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'Inter';

  // ---------------------------------------------------------------------------
  // DS 1 -- Escala tipografica principal
  // ---------------------------------------------------------------------------

  /// Titulo de enfermedad -- Peso maximo, tracking cerrado.
  static const TextStyle displayDisease = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25, // lineHeight 40px / fontSize 32px
    letterSpacing: -0.64, // -0.02em * 32
  );

  /// Titulo de enfermedad (mobile) -- Variante reducida.
  static const TextStyle displayDiseaseMobile = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.286, // 36px / 28px
  );

  /// Headline medium -- Subtitulos y secciones.
  static const TextStyle headlineMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.333, // 32px / 24px
  );

  /// Body large -- Texto de lectura principal ampliado.
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.556, // 28px / 18px
  );

  /// Body medium -- Texto de lectura estandar (minimo 16px).
  static const TextStyle bodyMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5, // 24px / 16px
  );

  /// Label medium -- Etiquetas de campos y botones.
  static const TextStyle labelMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.429, // 20px / 14px
    letterSpacing: 0.14, // 0.01em * 14
  );

  /// Status pill -- Texto de pills de estado (Saludable, En Riesgo).
  static const TextStyle statusPill = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.455, // 16px / 11px
    letterSpacing: 0.33, // 0.03em * 11
  );

  // ---------------------------------------------------------------------------
  // DS 2 -- Escala tipografica alternativa (nomenclatura en espanol)
  // ---------------------------------------------------------------------------

  /// Titulo XL -- Solo para pantallas de alto impacto.
  static const TextStyle tituloXl = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2, // 48px / 40px
    letterSpacing: -0.8, // -0.02em * 40
  );

  /// Titulo LG -- Encabezados principales.
  static const TextStyle tituloLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25, // 40px / 32px
    letterSpacing: -0.32, // -0.01em * 32
  );

  /// Titulo LG Mobile -- Variante mobile.
  static const TextStyle tituloLgMobile = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.214, // 34px / 28px
  );

  /// Titulo MD -- Subtitulos de seccion.
  static const TextStyle tituloMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.333, // 32px / 24px
  );

  /// Etiqueta bold -- Labels destacados en formularios.
  static const TextStyle etiquetaBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.429, // 20px / 14px
  );

  /// Etiqueta small -- Texto auxiliar y captions.
  static const TextStyle etiquetaSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.333, // 16px / 12px
  );
}
