// =============================================================================
// AgroGraph-MAS -- Paleta de Colores Centralizada
// =============================================================================
// Fuente: Stitch Project 9941199551312199248
//   DS 1: "AgroGraph-MAS Design System" (assets/41072a0a637a442f8a6c4c9c80d66e6f)
//   DS 2: "AgroGraph-MAS"               (assets/70fd5a4b76954b418550ed0d62419eea)
//
// REGLA: Toda referencia a color en la capa `presentation` de cualquier feature
//        DEBE consumir exclusivamente esta clase. Queda prohibido usar
//        Color(0xFF...) directamente en los widgets.
// =============================================================================

import 'package:flutter/material.dart';

/// Tokens de color del Design System de AgroGraph-MAS.
///
/// Los colores siguen la convencion Material 3 (named colors) con extensiones
/// semanticas propias del dominio agricola (offline, status pills, brand CTA).
abstract final class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // BRAND / SEMANTICOS (extraidos del Design.md de Stitch)
  // ---------------------------------------------------------------------------

  /// Verde Bosque -- Ancla primaria de marca.
  static const Color forestGreen = Color(0xFF2D6A4F);

  /// Ambar Calido -- Reservado EXCLUSIVAMENTE para CTAs primarios.
  static const Color warmAmber = Color(0xFFF4A261);

  /// Naranja Terracota -- Alertas criticas y advertencias de enfermedad.
  static const Color burntOrange = Color(0xFFE76F51);

  /// Gris Offline -- Indicador de estado de sincronizacion / sin conexion.
  static const Color offlineGrey = Color(0xFFADB5BD);

  /// Gris Offline oscuro -- Usado en pills "Sin conexion".
  static const Color offlineGreyDark = Color(0xFF6C757D);

  // ---------------------------------------------------------------------------
  // MATERIAL 3 -- PRIMARY
  // ---------------------------------------------------------------------------

  static const Color primary = Color(0xFF0F5238);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF2D6A4F);
  static const Color onPrimaryContainer = Color(0xFFA8E7C5);
  static const Color inversePrimary = Color(0xFF95D4B3);

  // Primary Fixed
  static const Color primaryFixed = Color(0xFFB1F0CE);
  static const Color primaryFixedDim = Color(0xFF95D4B3);
  static const Color onPrimaryFixed = Color(0xFF002114);
  static const Color onPrimaryFixedVariant = Color(0xFF0E5138);

  // ---------------------------------------------------------------------------
  // MATERIAL 3 -- SECONDARY
  // ---------------------------------------------------------------------------

  static const Color secondary = Color(0xFF006C48);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF92F7C3);
  static const Color onSecondaryContainer = Color(0xFF00734D);

  // Secondary Fixed
  static const Color secondaryFixed = Color(0xFF92F7C3);
  static const Color secondaryFixedDim = Color(0xFF75DAA8);
  static const Color onSecondaryFixed = Color(0xFF002113);
  static const Color onSecondaryFixedVariant = Color(0xFF005235);

  // ---------------------------------------------------------------------------
  // MATERIAL 3 -- TERTIARY
  // ---------------------------------------------------------------------------

  static const Color tertiary = Color(0xFF713900);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF8F4F14);
  static const Color onTertiaryContainer = Color(0xFFFFD1B1);

  // Tertiary Fixed
  static const Color tertiaryFixed = Color(0xFFFFDCC4);
  static const Color tertiaryFixedDim = Color(0xFFFFB780);
  static const Color onTertiaryFixed = Color(0xFF2F1400);
  static const Color onTertiaryFixedVariant = Color(0xFF6F3800);

  // ---------------------------------------------------------------------------
  // MATERIAL 3 -- ERROR
  // ---------------------------------------------------------------------------

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ---------------------------------------------------------------------------
  // MATERIAL 3 -- SURFACE / BACKGROUND
  // ---------------------------------------------------------------------------

  /// Fondo principal -- tono crema palido para reducir fatiga visual al sol.
  static const Color surface = Color(0xFFE9FEF5);
  static const Color surfaceBright = Color(0xFFE9FEF5);
  static const Color surfaceDim = Color(0xFFCADFD5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFE3F8EF);
  static const Color surfaceContainer = Color(0xFFDEF3E9);
  static const Color surfaceContainerHigh = Color(0xFFD8EDE3);
  static const Color surfaceContainerHighest = Color(0xFFD2E7DE);
  static const Color surfaceVariant = Color(0xFFD2E7DE);
  static const Color surfaceTint = Color(0xFF2C694E);

  static const Color onSurface = Color(0xFF0D1F19);
  static const Color onSurfaceVariant = Color(0xFF404943);

  static const Color inverseSurface = Color(0xFF22342E);
  static const Color inverseOnSurface = Color(0xFFE0F6EC);

  /// Background (alias a surface en M3, mantenido por claridad semantica).
  static const Color background = Color(0xFFE9FEF5);
  static const Color onBackground = Color(0xFF0D1F19);

  // ---------------------------------------------------------------------------
  // MATERIAL 3 -- OUTLINE
  // ---------------------------------------------------------------------------

  static const Color outline = Color(0xFF707973);
  static const Color outlineVariant = Color(0xFFBFC9C1);

  // ---------------------------------------------------------------------------
  // DS 2 -- VARIANTE ALTERNATIVA (assets/70fd5a4b76954b418550ed0d62419eea)
  // ---------------------------------------------------------------------------
  // Colores del segundo Design System que difieren del primero.
  // Utiles para variantes o para un futuro ThemeMode alternativo.

  /// Background del DS2 -- tono crema mas neutro, menor saturacion verde.
  static const Color surfaceDs2 = Color(0xFFF8FAF5);
  static const Color onSurfaceDs2 = Color(0xFF191C1A);
  static const Color onBackgroundDs2 = Color(0xFF191C1A);
  static const Color inverseSurfaceDs2 = Color(0xFF2E312E);
  static const Color inverseOnSurfaceDs2 = Color(0xFFEFF1EC);

  /// Secondary del DS2 -- Ambar/Arena como acento.
  static const Color secondaryDs2 = Color(0xFF8E4E14);
  static const Color secondaryContainerDs2 = Color(0xFFFFAB69);
  static const Color onSecondaryContainerDs2 = Color(0xFF783D01);

  /// Tertiary del DS2 -- Terracota/Peligro.
  static const Color tertiaryDs2 = Color(0xFF84270F);
  static const Color tertiaryContainerDs2 = Color(0xFFA43E24);
  static const Color onTertiaryContainerDs2 = Color(0xFFFFCFC4);

  // ---------------------------------------------------------------------------
  // COMPONENTES -- Colores funcionales del Design.md
  // ---------------------------------------------------------------------------

  /// Borde de tarjeta -- #6B8F71 al 20% opacidad.
  static const Color cardBorder = Color(0x336B8F71);

  /// Superficie de tarjeta (blanco puro, sin sombras).
  static const Color cardSurface = Color(0xFFFFFFFF);

  /// Fondo de pill "Saludable" (15% opacidad del verde).
  static const Color statusHealthyBg = Color(0x262D6A4F);
  static const Color statusHealthyText = Color(0xFF2D6A4F);

  /// Fondo de pill "En Riesgo" (15% opacidad del naranja).
  static const Color statusAtRiskBg = Color(0x26E76F51);
  static const Color statusAtRiskText = Color(0xFFE76F51);

  /// Fondo de pill Offline (15% opacidad del gris).
  static const Color statusOfflineBg = Color(0x26ADB5BD);
  static const Color statusOfflineText = Color(0xFF6C757D);

  /// Navegacion -- estado inactivo (texto secundario).
  static const Color navInactive = Color(0xFF6B8F71);

  /// Navegacion -- estado activo.
  static const Color navActive = Color(0xFF2D6A4F);

  // ---------------------------------------------------------------------------
  // STITCH APRENDIZ -- Tokens del feature aprendiz (Project 6524313850803988866)
  // Palette distinta a la del agricultor. Solo usar dentro de features/aprendiz.
  // ---------------------------------------------------------------------------

  static const Color aPrimary = Color(0xFF012D1D);
  static const Color aPrimaryContainer = Color(0xFF1B4332);
  static const Color aOnPrimary = Color(0xFFFFFFFF);
  static const Color aOnPrimaryContainer = Color(0xFF86AF99);
  static const Color aOnPrimaryFixed = Color(0xFF002114);
  static const Color aOnPrimaryFixedVariant = Color(0xFF274E3D);
  static const Color aPrimaryFixed = Color(0xFFC1ECD4);
  static const Color aPrimaryFixedDim = Color(0xFFA5D0B9);

  static const Color aSecondary = Color(0xFF2C694E);
  static const Color aSecondaryContainer = Color(0xFFAEEECB);
  static const Color aOnSecondaryContainer = Color(0xFF316E52);

  /// Naranja CTA — botones primarios y acciones urgentes del feature aprendiz.
  static const Color aOrange = Color(0xFFF4845F);

  /// Naranja acento — indicador activo del tab bar y resaltados.
  static const Color aOrangeAccent = Color(0xFFF88762);

  /// Fondo mint — background principal del feature aprendiz.
  static const Color aMint = Color(0xFFF0FAF3);

  static const Color aLightGreen = Color(0xFFD8F3DC);

  static const Color aSurface = Color(0xFFFCF9F8);
  static const Color aOnSurface = Color(0xFF1C1B1B);
  static const Color aSurfaceVariant = Color(0xFFE5E2E1);
  static const Color aOnSurfaceVariant = Color(0xFF414844);
  static const Color aSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color aSurfaceContainerLow = Color(0xFFF6F3F2);
  static const Color aSurfaceContainer = Color(0xFFF0EDED);
  static const Color aSurfaceContainerHigh = Color(0xFFEAE7E7);

  static const Color aOutline = Color(0xFF717973);
  static const Color aOutlineVariant = Color(0xFFC1C8C2);

  static const Color aTertiaryFixed = Color(0xFFFFDBD0);
  static const Color aOnTertiaryFixed = Color(0xFF390B00);
  static const Color aOnTertiaryFixedVariant = Color(0xFF7E2B0D);

  /// Fondo de tarjeta de advertencia (amarillo).
  static const Color aWarningBg = Color(0xFFFFF3CD);
  static const Color aWarningBorder = Color(0xFFFFE5A3);
  static const Color aWarningText = Color(0xFFB45309);

  /// Fondo de tarjeta de enfermedad (rojo suave).
  static const Color aDiseaseCardBg = Color(0xFFFFE5E5);
  static const Color aDiseaseCardBorder = Color(0xFFFFB4B4);
  static const Color aDiseaseCardText = Color(0xFF93000A);
}
