import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../bloc/parcel_bloc.dart';

/// Estado de error de [ParcelsPage] (ej. sin conexión), con reintento.
class ParcelsErrorState extends StatelessWidget {
  const ParcelsErrorState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xhuge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              color: AppColors.parcelsTextSecondary,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.parcelsTextSecondary),
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            ElevatedButton(
              onPressed: () =>
                  context.read<ParcelBloc>().add(const ParcelLoadRequested()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
