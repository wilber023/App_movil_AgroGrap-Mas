import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/parcel_entity.dart';
import '../pages/parcel_detail_page.dart';
import 'parcel_card_menu.dart';
import 'parcel_chips.dart';
import 'parcel_local_diagnosis_count.dart';
import 'parcel_phenological_bar.dart';
import 'parcels_helpers.dart';

/// Tarjeta individual de parcela en la lista de [ParcelsPage]: avatar de
/// cultivo, estado, conteo de diagnósticos locales y barra fenológica.
class ParcelListCard extends StatelessWidget {
  const ParcelListCard({super.key, required this.parcel});

  final ParcelEntity parcel;

  @override
  Widget build(BuildContext context) {
    final p = parcel;
    final statusColors = parcelStatusColors(p.status);
    final emoji = parcelCropEmoji(p.cropName);
    final diagCount = countLocalDiagnosesFor(p.seleccionId);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ParcelDetailPage(parcel: p)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.onPrimary,
              border: Border(
                left: BorderSide(color: statusColors.border, width: 4),
                top: BorderSide(
                  color: AppColors.parcelsBorderLight.withValues(alpha: 0.2),
                  width: 0.5,
                ),
                right: BorderSide(
                  color: AppColors.parcelsBorderLight.withValues(alpha: 0.2),
                  width: 0.5,
                ),
                bottom: BorderSide(
                  color: AppColors.parcelsBorderLight.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji avatar
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.parcelsChipGreenBg,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 25),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.parcelsTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              ParcelChip(
                                label: p.cropName,
                                bg: AppColors.parcelsChipGreenBg,
                                textColor: AppColors.parcelsChipGreenText,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '${p.areaSize.toStringAsFixed(1)} ${p.areaUnit}',
                                style: AppTypography.etiquetaSm.copyWith(
                                  color: AppColors.parcelsTextSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          if (p.region.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xxsPlus),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 11,
                                  color: AppColors.parcelsTextSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Expanded(
                                  child: Text(
                                    p.region,
                                    style: AppTypography.etiquetaSm.copyWith(
                                      color: AppColors.parcelsTextSecondary,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    ParcelCardMenu(parcel: p),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    ParcelStatusChip(
                      label: p.status,
                      bg: statusColors.chipBg,
                      textColor: statusColors.chipText,
                      icon: statusColors.icon,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Conteo de diagnósticos locales
                    if (diagCount > 0)
                      ParcelDiagCountChip(count: diagCount)
                    else if (p.lastDiagnosisAt != null) ...[
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.parcelsBorderLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Diag. ${parcelTimeAgo(p.lastDiagnosisAt!)}',
                        style: AppTypography.etiquetaSm.copyWith(
                          color: AppColors.parcelsTextSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ParcelPhenologicalBar(parcel: p),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
