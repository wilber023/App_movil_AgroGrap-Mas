import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/parcel_entity.dart';
import 'parcel_detail_helpers.dart';

/// Tarjeta hero de la pestaña "Resumen" de [ParcelDetailPage]: nombre,
/// cultivo, estado y datos rápidos (superficie / región / etapa).
class ParcelHeroCard extends StatelessWidget {
  const ParcelHeroCard({super.key, required this.parcel});

  final ParcelEntity parcel;

  @override
  Widget build(BuildContext context) {
    final statusBg = parcelStatusBg(parcel.status);
    final statusText = parcelStatusTextColor(parcel.status);
    final emoji = parcelDetailEmoji(parcel.cropName);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      decoration: parcelDetailCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji del cultivo
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.parcelsChipGreenBg,
                  borderRadius: BorderRadius.circular(AppRadius.lgXl),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.name,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.parcelsTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxsPlus),
                    Text(
                      parcel.cropName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.parcelsTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (parcel.status != 'Sin diagnostico')
                _chip(parcel.status, statusBg, statusText),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          const Divider(height: 1, thickness: 0.5, color: AppColors.parcelsDividerLight),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _infoTile(
                Icons.crop_square_outlined,
                '${parcel.areaSize.toStringAsFixed(1)} ${parcel.areaUnit}',
                'Superficie',
              ),
              if (parcel.region.isNotEmpty) ...[
                _infoTile(Icons.location_on_outlined, parcel.region, 'Región'),
              ],
              _infoTile(Icons.timeline_outlined, parcel.stageName, 'Etapa'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.parcelsTextSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.parcelsTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.parcelsTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
