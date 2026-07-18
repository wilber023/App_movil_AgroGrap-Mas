import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

// =============================================================================
// Helpers puramente de presentacion, compartidos por los widgets de
// ParcelsPage. No agregan ningun dato nuevo: solo formatean o clasifican
// visualmente datos que ya expone ParcelEntity.
// =============================================================================

const List<String> parcelPhenologicalStages = [
  'Siembra',
  'Vegetativo',
  'Floracion',
  'Cosecha',
];

const Map<String, String> parcelCropEmojiMap = {
  'Calabaza': '🍈',
  'Frijol': '🫘',
  'Manzana': '🍎',
  'Mora': '🫐',
  'Cereza': '🍒',
  'Maíz': '🌽',
  'Durazno': '🍑',
  'Uva': '🍇',
  'Naranja': '🍊',
  'Pimienta': '🌶️',
  'Papa': '🥔',
  'Frambuesa': '🍓',
  'Soja': '🌱',
  'Fresa': '🍓',
  'Tomate': '🍅',
};

String parcelCropEmoji(String cropName) => parcelCropEmojiMap[cropName] ?? '🌿';

class ParcelStatusColors {
  final Color border;
  final Color chipBg;
  final Color chipText;
  final IconData icon;
  const ParcelStatusColors({
    required this.border,
    required this.chipBg,
    required this.chipText,
    required this.icon,
  });
}

ParcelStatusColors parcelStatusColors(String status) {
  switch (status) {
    case 'Alerta':
      return const ParcelStatusColors(
        border: AppColors.burntOrange,
        chipBg: AppColors.parcelsChipAlertBg,
        chipText: AppColors.parcelsChipAlertText,
        icon: Icons.warning_amber_rounded,
      );
    case 'Seguimiento':
      return const ParcelStatusColors(
        border: AppColors.warmAmber,
        chipBg: AppColors.parcelsChipFollowBg,
        chipText: AppColors.parcelsChipFollowText,
        icon: Icons.visibility_outlined,
      );
    case 'Saludable':
      return const ParcelStatusColors(
        border: AppColors.forestGreen,
        chipBg: AppColors.parcelsChipGreenBg,
        chipText: AppColors.parcelsChipGreenText,
        icon: Icons.check_circle_outline_rounded,
      );
    default: // 'Sin diagnostico' y cualquier otro
      return const ParcelStatusColors(
        border: AppColors.parcelsBorderLight,
        chipBg: AppColors.parcelsNeutralChipBg,
        chipText: AppColors.parcelsTextSecondary,
        icon: Icons.radio_button_unchecked_outlined,
      );
  }
}

String parcelTimeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 1) {
    return 'hace ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
  }
  if (diff.inHours >= 1) return 'hace ${diff.inHours} h';
  return 'hace un momento';
}
