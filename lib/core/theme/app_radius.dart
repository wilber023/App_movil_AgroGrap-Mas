// =============================================================================
// AgroGraph-MAS -- Radios de Borde Centralizados
// =============================================================================
// Tokens de border-radius extraidos de los valores ya utilizados en la capa
// `presentation`. Cada token conserva el valor numerico original con el que
// fue detectado -- no se introdujeron ni redondearon valores nuevos, para
// garantizar cero cambios visuales al migrar literales existentes.
//
// REGLA: Todo BorderRadius.circular(...) en la capa `presentation` de
//        cualquier feature DEBE consumir esta clase en vez de un literal.
// =============================================================================

/// Tokens de radio de borde del Design System de AgroGraph-MAS.
abstract final class AppRadius {
  AppRadius._();

  static const double xs = 2;
  static const double xsPlus = 3;
  static const double sm = 4;
  static const double smMd = 6;
  static const double md = 8;
  static const double mdLg = 10;
  static const double lg = 11;
  static const double lgXl = 12;
  static const double xl = 14;
  static const double xlPlus = 16;
  static const double xxl = 18;
  static const double xxlPlus = 20;
  static const double huge = 22;
  static const double xhuge = 24;

  /// Radio "pill" -- usado para chips y badges totalmente redondeados.
  static const double pill = 999;
}
