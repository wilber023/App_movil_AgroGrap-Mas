import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/parcel_entity.dart';
import 'parcels_helpers.dart';

/// Barra de progreso de etapa fenológica (Siembra/Vegetativo/Floracion/
/// Cosecha) mostrada en cada tarjeta de [ParcelsPage].
class ParcelPhenologicalBar extends StatelessWidget {
  const ParcelPhenologicalBar({super.key, required this.parcel});

  final ParcelEntity parcel;

  @override
  Widget build(BuildContext context) {
    final p = parcel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Etapa fenologica',
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.parcelsTextSecondary,
                fontSize: 10,
              ),
            ),
            Text(
              p.stageName,
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.parcelsTextPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: p.stageProgress,
              backgroundColor: AppColors.parcelsTrackGrey,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.forestGreen,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(parcelPhenologicalStages.length, (i) {
            final reached = i <= p.stageIndex;
            return Column(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached ? AppColors.forestGreen : AppColors.parcelsTrackGrey,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  parcelPhenologicalStages[i],
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    color: reached ? AppColors.parcelsTextPrimary : AppColors.parcelsTextSecondary,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
