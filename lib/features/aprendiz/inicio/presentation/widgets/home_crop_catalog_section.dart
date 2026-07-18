import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/crop_catalog_item_entity.dart';

/// Seccion "Mis cultivos": catalogo real de cultivos que ofrece Registrar
/// Cultivo, con el que el usuario realmente tiene activo marcado "En curso"
/// — el resto solo indica que esta disponible para registrar, nunca que ya
/// lo tenga.
class HomeCropCatalogSection extends StatelessWidget {
  final List<CropCatalogItemEntity> catalog;
  final VoidCallback onViewAll;
  final ValueChanged<CropCatalogItemEntity> onSelectCrop;

  const HomeCropCatalogSection({
    super.key,
    required this.catalog,
    required this.onViewAll,
    required this.onSelectCrop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mis cultivos',
              style: AppTypography.agendaSectionTitle.copyWith(color: AppColors.aPrimary),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver todos',
                    style: AppTypography.etiquetaBold.copyWith(color: AppColors.aSecondary),
                  ),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.aSecondary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: catalog.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
            itemBuilder: (context, i) {
              final item = catalog[i];
              return _CropChip(item: item, onTap: () => onSelectCrop(item));
            },
          ),
        ),
      ],
    );
  }
}

class _CropChip extends StatelessWidget {
  final CropCatalogItemEntity item;
  final VoidCallback onTap;

  const _CropChip({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.aSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: item.isActive ? AppColors.aSecondary : AppColors.aOutlineVariant,
            width: item.isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 24, height: 1.1)),
            const SizedBox(height: AppSpacing.xsPlus),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.etiquetaSm.copyWith(
                fontSize: 11,
                height: 1.1,
                color: AppColors.aOnSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              item.isActive ? 'En curso' : 'Disponible',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.etiquetaSm.copyWith(
                fontSize: 9,
                height: 1.1,
                color: item.isActive ? AppColors.aSecondary : AppColors.aOnSurfaceVariant,
                fontWeight: item.isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
