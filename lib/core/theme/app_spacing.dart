// =============================================================================
// AgroGraph-MAS -- Espaciado Centralizado
// =============================================================================
// Tokens de espaciado (padding, margin, gaps) extraidos de los valores ya
// utilizados en la capa `presentation`. Cada token conserva el valor
// numerico original con el que fue detectado -- no se introdujeron ni
// redondearon valores nuevos, para garantizar cero cambios visuales al
// migrar literales existentes a estos tokens.
//
// REGLA: Toda referencia a espaciado en la capa `presentation` de cualquier
//        feature DEBE consumir esta clase en vez de valores numericos
//        literales.
// =============================================================================

/// Tokens de espaciado del Design System de AgroGraph-MAS.
abstract final class AppSpacing {
  AppSpacing._();

  static const double none = 0;
  static const double hairline = 1;
  static const double xxs = 2;
  static const double xxsPlus = 3;
  static const double xs = 4;
  static const double xsPlus = 5;
  static const double sm = 6;
  static const double smMd = 7;
  static const double md = 8;
  static const double mdLg = 9;
  static const double lg = 10;
  static const double lgXl = 11;
  static const double xl = 12;
  static const double xlPlus = 13;
  static const double xxl = 14;
  static const double xxlMid = 15;
  static const double xxlPlus = 16;
  static const double xxxl = 18;
  static const double huge = 20;
  static const double hugePlus = 22;
  static const double xhuge = 24;
  static const double xhugePlus = 26;
  static const double xxhuge = 28;
  static const double xxhugePlus = 30;
  static const double giant = 32;
  static const double giantMinus = 34;
  static const double giantPlus = 36;
  static const double xgiant = 40;
  static const double xgiantMid = 46;
  static const double xgiantPlus = 48;
  static const double xxgiant = 52;
  static const double colossal = 80;
  static const double behemoth = 100;
  static const double titan = 120;
}
