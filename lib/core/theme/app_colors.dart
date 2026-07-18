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

  /// Azul informativo -- Usado en la Agenda para el indicador "Completadas"
  /// y el estado "Próximo" (distinto de las alertas rojo/naranja/ámbar).
  static const Color infoBlue = Color(0xFF3B7DDD);

  /// Índigo/morado -- Color de identidad decorativa para tarjetas de la
  /// Agenda (variedad visual entre tratamientos, no indica urgencia).
  static const Color agendaIndigo = Color(0xFF7C6FEA);

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

  /// Fondo del banner de alerta epidemiologica (rosa/coral suave).
  static const Color alertBannerBg = Color(0xFFFFF1EE);

  /// Fondo de tarjeta de advertencia (amarillo).
  static const Color aWarningBg = Color(0xFFFFF3CD);
  static const Color aWarningBorder = Color(0xFFFFE5A3);
  static const Color aWarningText = Color(0xFFB45309);

  /// Fondo de tarjeta de enfermedad (rojo suave).
  static const Color aDiseaseCardBg = Color(0xFFFFE5E5);
  static const Color aDiseaseCardBorder = Color(0xFFFFB4B4);
  static const Color aDiseaseCardText = Color(0xFF93000A);

  /// Fondo del icono de evento "Fertilización" en el historial de cultivo.
  static const Color aFertilizerBg = Color(0xFFBBDEFB);

  /// Color del icono de evento "Fertilización" en el historial de cultivo.
  static const Color aFertilizerIcon = Color(0xFF1565C0);

  // ---------------------------------------------------------------------------
  // AUTH -- Campo de texto y botones premium (login/register)
  // ---------------------------------------------------------------------------

  /// Fondo del campo de texto -- verde salvia extremadamente apagado.
  static const Color authFieldBg = Color(0xFFF4F8F6);

  /// Gris piedra atenuado para iconos outline del campo de texto.
  static const Color authFieldIcon = Color(0xFF9BA89E);

  /// Placeholder muy suave del campo de texto.
  static const Color authFieldHint = Color(0xFFAAB9B3);

  /// Texto del usuario en el campo -- verde bosque profundo (no negro puro).
  static const Color authFieldText = Color(0xFF2A3D35);

  /// Etiqueta del campo -- verde musgo medio.
  static const Color authFieldLabel = Color(0xFF56706A);

  /// Verde foco del campo de texto -- indica actividad sin agresividad.
  static const Color authFieldFocusGreen = Color(0xFF4A7C59);

  /// Terracota quemada / arcilla -- boton CTA primario de Auth.
  static const Color authTerracota = Color(0xFFCB6E44);

  /// Fondo superior del degradado de Login/Register -- eucalipto desaturado.
  static const Color authBgTop = Color(0xFFE6EFEB);

  /// Fondo intermedio del degradado -- salvia blanco medio.
  static const Color authBgMid = Color(0xFFF2F7F4);

  /// Fondo inferior del degradado -- hueso almendra.
  static const Color authBgBottom = Color(0xFFF9FBFA);

  /// Texto secundario de Auth -- musgo medio.
  static const Color authInkMuted = Color(0xFF7A8E84);

  /// Fondo del selector de rol (tab switch) -- se funde con el degradado.
  static const Color authRoleSwitchBg = Color(0xFFD9E6DF);

  /// Color de los divisores decorativos en Auth.
  static const Color authDivider = Color(0xFFCBD9D3);

  /// Extremo del degradado del ícono de marca en Login/Register.
  static const Color authBrandGradientEnd = Color(0xFF1B4332);

  /// Titulo de la pantalla de Registro -- verde bosque casi negro.
  static const Color authHeaderTitle = Color(0xFF1B2D27);

  /// Texto/iconos secundarios de Registro -- verde salvia medio.
  static const Color authMutedSage = Color(0xFF6B8F71);

  /// Acento del banner "Registrando como: Agricultor".
  static const Color authAgricultorAccent = Color(0xFF2E7D32);

  /// Fondo full-screen del Splash -- verde oscuro solido.
  static const Color authSplashBg = Color(0xFF1B5E20);

  /// Subtitulo del Splash -- verde claro.
  static const Color authSplashSubtitle = Color(0xFF81C784);

  /// Alias semantico de [Colors.white70] -- track de progreso en Splash.
  static const Color white70 = Colors.white70;

  /// Alias semantico de [Colors.transparent] para cumplir la regla de no
  /// usar `Colors.*` directamente en la capa `presentation`.
  static const Color transparent = Colors.transparent;

  /// Alias semantico de [Colors.black] -- usado en sombras difuminadas.
  static const Color black = Colors.black;

  /// Alias semantico de [Colors.grey] (Material grey 500).
  static const Color grey = Colors.grey;

  /// Alias semantico de [Colors.white] para cumplir la regla de no usar
  /// `Colors.*` directamente en la capa `presentation`.
  static const Color white = Colors.white;

  // ---------------------------------------------------------------------------
  // HOME AGRICULTOR -- Tokens puntuales de home_page.dart
  // ---------------------------------------------------------------------------

  /// Fondo de la pantalla de Inicio (Agricultor).
  static const Color homeBg = Color(0xFFF2F8F4);

  /// Fondo del icono en el estado vacio de "Cultivos activos".
  static const Color homeEmptyIconBg = Color(0xFFEAF3DE);

  /// Color del icono en el estado vacio de "Cultivos activos".
  static const Color homeEmptyIconFg = Color(0xFF52B788);

  /// Acento verde de la ilustracion decorativa de la tarjeta de escaneo.
  static const Color homeScanAccent = Color(0xFF6FE3A5);

  // ---------------------------------------------------------------------------
  // PARCELS -- Tokens puntuales de parcels_page.dart / add_parcel_page.dart /
  // parcel_detail_page.dart
  // ---------------------------------------------------------------------------

  static const Color parcelsBg = Color(0xFFF8FAF5);
  static const Color parcelsTextPrimary = Color(0xFF1B2D27);
  static const Color parcelsTextSecondary = Color(0xFF6B8F71);
  static const Color parcelsBorderLight = Color(0xFFADB5BD);
  static const Color parcelsChipGreenBg = Color(0xFFEAF3DE);
  static const Color parcelsChipGreenText = Color(0xFF27500A);
  static const Color parcelsChipAlertBg = Color(0xFFFDECEA);
  static const Color parcelsChipAlertText = Color(0xFFA32D2D);
  static const Color parcelsChipFollowBg = Color(0xFFFFF3E0);
  static const Color parcelsChipFollowText = Color(0xFF7B4A10);
  static const Color parcelsTrackGrey = Color(0xFFE2EBE6);
  static const Color parcelsChipBlueBg = Color(0xFFE6F1FB);
  static const Color parcelsChipBlueText = Color(0xFF0C447C);
  static const Color parcelsAddGreen = Color(0xFF52B788);
  static const Color parcelsAddBorder = Color(0xFFA8C5B0);

  /// Fondo del chip "Sin diagnostico" (gris neutro).
  static const Color parcelsNeutralChipBg = Color(0xFFF0F2F5);

  /// Texto sobre boton ambar (contraste alto, marron oscuro).
  static const Color onWarmAmber = Color(0xFF4A2800);

  /// Fondo gris apagado -- banner offline / chip no seleccionado (Parcels).
  static const Color parcelsMutedBg = Color(0xFFF1F1F1);

  /// Fondo gris claro -- catalogo vacio / tarjeta no seleccionada (Parcels).
  static const Color parcelsSubtleBg = Color(0xFFF5F5F5);

  /// Texto gris de opcion no seleccionada (Parcels).
  static const Color parcelsUnselectedText = Color(0xFF888888);

  /// Subtitulo verde claro en el AppBar de Detalle de Parcela.
  static const Color parcelsAppBarSubtitle = Color(0xFFADD5B8);

  /// Color de divisores sutiles en Detalle de Parcela.
  static const Color parcelsDividerLight = Color(0xFFE8EEE7);

  /// Borde sutil de tarjetas en Modo sin Conexion (paquetes no descargados).
  static const Color offlineCardBorder = Color(0xFFE5EAF0);

  /// Rojo oscuro alternativo -- SnackBar de error en Diagnostico.
  static const Color errorDark = Color(0xFFA32D2D);

  /// Fondo de miniatura placeholder en tarjetas de historial de diagnostico.
  static const Color diagnosisThumbBg = Color(0xFFD8EAD0);

  /// Inicio del degradado oscuro de fondo en la pantalla de camara.
  static const Color diagnosisCameraGradientStart = Color(0xFF0B1F18);

  /// Rojo brillante -- errores de validacion sobre fondo oscuro (camara).
  static const Color errorBright = Color(0xFFFF6B6B);

  // ---------------------------------------------------------------------------
  // DIAGNOSIS RESULT -- Tokens puntuales de diagnosis_result_page.dart
  // ---------------------------------------------------------------------------

  static const Color diagnosisBg = Color(0xFFF5F7F2);
  static const Color diagnosisRiskHigh = Color(0xFFD32F2F);
  static const Color diagnosisRiskMed = Color(0xFFF57C00);
  static const Color diagnosisRiskLow = Color(0xFF388E3C);
  static const Color diagnosisMetricBlue = Color(0xFF1565C0);

  /// Fin del degradado del hero cuando no hay foto (fallback visual).
  static const Color diagnosisHeroGradientEnd = Color(0xFF1B3A2A);

  /// Overlay superior del degradado oscuro sobre el hero (47% opacidad negra).
  static const Color diagnosisHeroOverlayStart = Color(0x77000000);

  /// Overlay inferior del degradado oscuro sobre el hero (80% opacidad negra).
  static const Color diagnosisHeroOverlayEnd = Color(0xCC000000);

  /// Verde del badge "Diagnostico completado" sobre el hero.
  static const Color diagnosisCompletedBadge = Color(0xFF1B7A3C);

  /// Borde ambar suave de la tarjeta de avisos.
  static const Color diagnosisAmberBorder = Color(0xFFFFCC80);

  /// Fondo de la tarjeta "Analisis IA" (verde muy palido).
  static const Color diagnosisAnalysisCardBg = Color(0xFFF2F8F4);

  /// Naranja del icono de estado de error en Productos / tipo Insecticida.
  static const Color diagnosisInsecticida = Color(0xFFC45E0A);

  /// Colores de la barra gradiente de nivel de infeccion.
  static const Color diagnosisInfectionGreen = Color(0xFF4CAF50);
  static const Color diagnosisInfectionYellow = Color(0xFFFFC107);
  static const Color diagnosisInfectionOrange = Color(0xFFFF5722);

  /// Badge "ECOLOGICO" de productos biologicos.
  static const Color diagnosisEcoBadge = Color(0xFF2E7D32);

  /// Badge "MAS ECONOMICO" de productos.
  static const Color diagnosisEconomicBadge = Color(0xFF455A64);

  /// Colores por tipo de producto agroquimico.
  static const Color diagnosisFungicida = Color(0xFF1B7A3C);
  static const Color diagnosisHerbicida = Color(0xFF0A7A6B);
  static const Color diagnosisFertilizante = Color(0xFF1A4DB5);
  static const Color diagnosisBiologico = Color(0xFF6B1AA8);
  static const Color diagnosisOtherProduct = Color(0xFF5C5C5C);

  /// Fondo del placeholder de imagen de producto.
  static const Color diagnosisProductImageBg = Color(0xFFF0F4F0);

  /// Colores del skeleton loader animado (shimmer).
  static const Color diagnosisSkeletonLight = Color(0xFFF2F2F2);
  static const Color diagnosisSkeletonDark = Color(0xFFE4E4E4);
}
