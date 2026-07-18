import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/parcel_entity.dart';
import 'parcel_detail_helpers.dart';

/// Tarjeta "Datos registrados" en la pestaña "Resumen" de
/// [ParcelDetailPage].
class ParcelDataCard extends StatelessWidget {
  const ParcelDataCard({super.key, required this.parcel});

  final ParcelEntity parcel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: parcelDetailCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos registrados',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.parcelsTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _dataRow(Icons.eco_outlined, 'Cultivo', parcel.cropName),
          _divider(),
          _dataRow(
            Icons.crop_square_outlined,
            'Superficie',
            '${parcel.areaSize.toStringAsFixed(1)} ${parcel.areaUnit}',
          ),
          if (parcel.region.isNotEmpty) ...[
            _divider(),
            _dataRow(Icons.location_on_outlined, 'Región', parcel.region),
          ],
          if (parcel.fechaSiembra != null) ...[
            _divider(),
            _dataRow(
              Icons.calendar_today_outlined,
              'Fecha de siembra',
              parcelDetailFormatDate(parcel.fechaSiembra!),
            ),
          ],
          _divider(),
          _dataRow(Icons.timeline_outlined, 'Etapa actual', parcel.stageName),
          _divider(),
          _dataRow(
            Icons.monitor_heart_outlined,
            'Estado de salud',
            parcel.status,
          ),
        ],
      ),
    );
  }

  Widget _dataRow(IconData icon, String label, String value) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.parcelsTextSecondary),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.parcelsTextSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.parcelsTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    thickness: 0.5,
    color: AppColors.parcelsBorderLight.withValues(alpha: 0.2),
  );
}
