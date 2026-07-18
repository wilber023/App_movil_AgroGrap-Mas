import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';

// =============================================================================
// Helpers puramente de presentacion, compartidos por los widgets de
// ParcelDetailPage.
// =============================================================================

const Map<String, String> parcelDetailEmojiMap = {
  'Calabaza': '🍈',
  'Frijol': '🫘',
  'Maíz': '🌽',
  'Papa': '🥔',
  'Tomate': '🍅',
};

String parcelDetailEmoji(String cropName) => parcelDetailEmojiMap[cropName] ?? '🌿';

String parcelDetailFormatDate(DateTime dt) {
  const months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

/// Colores de estado de la parcela (hero card): solo 3 casos, "Sin
/// diagnostico" y cualquier otro caen al color por defecto (verde).
Color parcelStatusBg(String status) {
  switch (status) {
    case 'Alerta':
      return AppColors.parcelsChipAlertBg;
    case 'Seguimiento':
      return AppColors.parcelsChipFollowBg;
    default:
      return AppColors.parcelsChipGreenBg;
  }
}

Color parcelStatusTextColor(String status) {
  switch (status) {
    case 'Alerta':
      return AppColors.parcelsChipAlertText;
    case 'Seguimiento':
      return AppColors.parcelsChipFollowText;
    default:
      return AppColors.parcelsChipGreenText;
  }
}

/// Colores de estado de un diagnóstico (tarjeta de historial): distingue
/// explícitamente "Saludable" del resto (azul neutro por defecto).
Color diagnosisStatusBg(String status) {
  switch (status) {
    case 'Alerta':
      return AppColors.parcelsChipAlertBg;
    case 'Seguimiento':
      return AppColors.parcelsChipFollowBg;
    case 'Saludable':
      return AppColors.parcelsChipGreenBg;
    default:
      return AppColors.parcelsChipBlueBg;
  }
}

Color diagnosisStatusTextColor(String status) {
  switch (status) {
    case 'Alerta':
      return AppColors.parcelsChipAlertText;
    case 'Seguimiento':
      return AppColors.parcelsChipFollowText;
    case 'Saludable':
      return AppColors.parcelsChipGreenText;
    default:
      return AppColors.parcelsChipBlueText;
  }
}

BoxDecoration parcelDetailCardDecoration() => BoxDecoration(
  color: AppColors.onPrimary,
  borderRadius: BorderRadius.circular(AppRadius.xl),
  border: Border.all(color: AppColors.parcelsBorderLight.withValues(alpha: 0.3), width: 0.5),
  boxShadow: [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);
