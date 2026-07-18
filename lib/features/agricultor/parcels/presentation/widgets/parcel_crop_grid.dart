import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/cultivo_entity.dart';

/// Grid de selección de cultivo principal en [AddParcelPage]: estado de
/// carga, error con reintento, o grid de tarjetas por cultivo del catálogo.
class ParcelCropGrid extends StatelessWidget {
  const ParcelCropGrid({
    super.key,
    required this.catalogLoading,
    required this.catalog,
    required this.selectedIndex,
    required this.emojiFor,
    required this.onSelected,
    required this.onRetry,
  });

  final bool catalogLoading;
  final List<CultivoEntity> catalog;
  final int selectedIndex;
  final String Function(String cropName) emojiFor;
  final ValueChanged<int> onSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (catalogLoading) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.forestGreen),
        ),
      );
    }
    if (catalog.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.parcelsSubtleBg,
          borderRadius: BorderRadius.circular(AppRadius.mdLg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'No se pudo cargar el catálogo de cultivos.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.parcelsBorderLight),
              ),
            ),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Reintentar',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.15,
      ),
      itemCount: catalog.length,
      itemBuilder: (context, i) {
        final isSelected = i == selectedIndex;
        final cultivo = catalog[i];
        final emoji = emojiFor(cultivo.nombre);
        return GestureDetector(
          onTap: () => onSelected(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.parcelsChipGreenBg
                  : AppColors.parcelsSubtleBg,
              borderRadius: BorderRadius.circular(AppRadius.lgXl),
              border: Border.all(
                color: isSelected
                    ? AppColors.forestGreen
                    : AppColors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: AppSpacing.xsPlus),
                Text(
                  cultivo.nombre,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.forestGreen
                        : AppColors.parcelsUnselectedText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
