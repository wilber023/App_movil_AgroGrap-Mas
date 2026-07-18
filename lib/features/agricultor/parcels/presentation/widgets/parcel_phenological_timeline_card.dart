import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/parcel_entity.dart';
import 'parcel_detail_helpers.dart';

/// Timeline de ciclo fenológico (Siembra/Vegetativo/Floración/Cosecha) en
/// la pestaña "Resumen" de [ParcelDetailPage].
class ParcelPhenologicalTimelineCard extends StatelessWidget {
  const ParcelPhenologicalTimelineCard({super.key, required this.parcel});

  final ParcelEntity parcel;

  static const _stages = [
    (Icons.spa_outlined, 'Siembra', 'Establecimiento del cultivo'),
    (Icons.eco_outlined, 'Vegetativo', 'Crecimiento de hojas y tallos'),
    (Icons.local_florist_outlined, 'Floración', 'Desarrollo floral'),
    (Icons.agriculture_outlined, 'Cosecha', 'Madurez y recolección'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      decoration: parcelDetailCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ciclo fenológico',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.parcelsTextPrimary,
                ),
              ),
              if (parcel.fechaSiembra != null)
                Text(
                  'Siembra: ${parcelDetailFormatDate(parcel.fechaSiembra!)}',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.parcelsTextSecondary),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxlPlus),
          ...List.generate(_stages.length, (i) {
            final (icon, label, desc) = _stages[i];
            final isCompleted = i < parcel.stageIndex;
            final isCurrent = i == parcel.stageIndex;
            final isFuture = i > parcel.stageIndex;
            final isLast = i == _stages.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna izquierda: círculo + línea
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Container(
                        width: isCurrent ? 26 : 18,
                        height: isCurrent ? 26 : 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFuture
                              ? AppColors.transparent
                              : isCompleted
                              ? AppColors.forestGreen
                              : AppColors.onPrimary,
                          border: Border.all(
                            color: isFuture
                                ? AppColors.parcelsTrackGrey
                                : AppColors.forestGreen,
                            width: isCurrent ? 2.5 : 1.5,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 10,
                                  color: AppColors.onPrimary,
                                )
                              : isCurrent
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.forestGreen,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 48,
                          color: i < parcel.stageIndex
                              ? AppColors.forestGreen
                              : AppColors.parcelsTrackGrey,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Columna derecha: label + descripción
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isCurrent ? AppSpacing.hairline : AppSpacing.none,
                      bottom: isLast ? AppSpacing.none : AppSpacing.giantMinus,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              icon,
                              size: 14,
                              color: isFuture
                                  ? AppColors.parcelsBorderLight
                                  : AppColors.forestGreen,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isFuture ? AppColors.parcelsTextSecondary : AppColors.parcelsTextPrimary,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.forestGreen,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Text(
                                  'Actual',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          desc,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isFuture ? AppColors.parcelsBorderLight : AppColors.parcelsTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
