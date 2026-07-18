import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'parcels_search_bar.dart';

/// Estado vacío de [ParcelsPage] cuando el agricultor no tiene parcelas.
class ParcelsEmptyState extends StatelessWidget {
  const ParcelsEmptyState({super.key, required this.onAddParcel});

  final VoidCallback onAddParcel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
      child: Column(
        children: [
          const ParcelsSearchBar(),
          const Spacer(),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.parcelsChipGreenBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_florist_outlined,
              color: AppColors.parcelsAddGreen,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.xxlPlus),
          Text(
            'Aun no tienes parcelas',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.parcelsTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
            child: Text(
              'Registra tu primera parcela para recibir diagnosticos precisos.',
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.parcelsTextSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xxlPlus),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onAddParcel,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmAmber,
                foregroundColor: AppColors.onWarmAmber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lgXl),
                ),
              ),
              child: const Text(
                'Registrar parcela',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
