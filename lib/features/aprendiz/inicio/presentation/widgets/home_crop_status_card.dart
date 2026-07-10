import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/crop_status_summary_entity.dart';

/// Invitacion a registrar un cultivo cuando el usuario aun no tiene uno
/// activo. Cuando si hay un cultivo registrado, la pantalla usa
/// `HomeCropStageCard` en su lugar (que ya incluye el diagnostico mas
/// reciente y la etapa real).
class HomeCropStatusCard extends StatelessWidget {
  final CropStatusSummaryEntity status;
  final VoidCallback onRegisterCrop;

  const HomeCropStatusCard({super.key, required this.status, required this.onRegisterCrop});

  @override
  Widget build(BuildContext context) {
    if (status.hasCropPlan) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado del cultivo',
            style: AppTypography.agendaSectionTitle.copyWith(fontSize: 15, color: AppColors.aPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Aún no tienes un cultivo registrado.',
            style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRegisterCrop,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.aSecondary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Registrar cultivo',
                style: AppTypography.labelMd.copyWith(color: AppColors.aOnPrimary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
