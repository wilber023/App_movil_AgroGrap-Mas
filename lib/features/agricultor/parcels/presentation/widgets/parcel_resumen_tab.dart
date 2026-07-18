import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/parcel_entity.dart';
import 'parcel_data_card.dart';
import 'parcel_hero_card.dart';
import 'parcel_phenological_timeline_card.dart';

/// Pestaña "Resumen" de [ParcelDetailPage]: hero card, ciclo fenológico y
/// datos registrados.
class ParcelResumenTab extends StatelessWidget {
  const ParcelResumenTab({super.key, required this.parcel});

  final ParcelEntity parcel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.behemoth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ParcelHeroCard(parcel: parcel),
          const SizedBox(height: AppSpacing.xl),
          ParcelPhenologicalTimelineCard(parcel: parcel),
          const SizedBox(height: AppSpacing.xl),
          ParcelDataCard(parcel: parcel),
        ],
      ),
    );
  }
}
