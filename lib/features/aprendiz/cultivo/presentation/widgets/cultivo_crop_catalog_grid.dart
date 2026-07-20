import 'package:flutter/material.dart';

import '../../../../../core/constants/supported_crops.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../agricultor/parcels/domain/entities/cultivo_entity.dart';
import 'cultivo_selectable_grid_card.dart';

/// Grid de seleccion del cultivo a sembrar, alimentado por el catalogo real
/// del microservicio de Cultivos (`GET /cultivos`), filtrado a los cultivos
/// soportados por el modelo CNN de diagnostico ([SupportedCrops]). Cubre
/// carga, error con reintento y seleccion, igual que `ParcelCropGrid` en el
/// flujo equivalente del Agricultor.
class CultivoCropCatalogGrid extends StatelessWidget {
  final bool isLoading;
  final List<CultivoEntity> catalog;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onRetry;

  const CultivoCropCatalogGrid({
    super.key,
    required this.isLoading,
    required this.catalog,
    required this.selectedIndex,
    required this.onSelected,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator(color: AppColors.aSecondary)),
      );
    }
    if (catalog.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.aSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.mdLg),
          border: Border.all(color: AppColors.aOutlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'No se pudo cargar el catálogo de cultivos.',
                style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: AppColors.aSecondary),
              child: const Text('Reintentar'),
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
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        childAspectRatio: 1.0,
      ),
      itemCount: catalog.length,
      itemBuilder: (context, i) {
        final cultivo = catalog[i];
        return CultivoSelectableGridCard(
          icon: Text(SupportedCrops.emojiFor(cultivo.nombre), style: const TextStyle(fontSize: 26)),
          label: cultivo.nombre,
          isSelected: selectedIndex == i,
          onTap: () => onSelected(i),
        );
      },
    );
  }
}
