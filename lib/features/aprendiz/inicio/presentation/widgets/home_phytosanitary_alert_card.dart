import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/phytosanitary_alert_entity.dart';

/// Tarjeta de alerta fitosanitaria/epidemiologica de la region. El backend
/// aun no expone este dato: mientras tanto siempre llega el estado neutral
/// real (`PhytosanitaryAlertLevel.none`), nunca un dato inventado.
class HomePhytosanitaryAlertCard extends StatelessWidget {
  final PhytosanitaryAlertEntity alert;

  const HomePhytosanitaryAlertCard({super.key, required this.alert});

  String get _levelLabel => switch (alert.level) {
        PhytosanitaryAlertLevel.none => '',
        PhytosanitaryAlertLevel.low => 'Nivel bajo',
        PhytosanitaryAlertLevel.moderate => 'Nivel medio',
        PhytosanitaryAlertLevel.high => 'Nivel alto',
      };

  @override
  Widget build(BuildContext context) {
    final isNone = alert.level == PhytosanitaryAlertLevel.none;
    final bg = isNone ? AppColors.aSurfaceContainerLowest : AppColors.aDiseaseCardBg;
    final border = isNone ? AppColors.aOutlineVariant : AppColors.aDiseaseCardBorder;
    final iconColor = isNone ? AppColors.aSecondary : AppColors.aDiseaseCardText;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isNone ? Icons.shield_outlined : Icons.report_gmailerrorred_outlined,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Alerta epidemiológica',
                  style: AppTypography.agendaSectionTitle.copyWith(fontSize: 14, color: AppColors.aPrimary),
                ),
              ),
              if (!isNone)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xxsPlus,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.aOrange,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _levelLabel,
                    style: AppTypography.etiquetaSm.copyWith(
                      fontSize: 9,
                      color: AppColors.aOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            alert.message,
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant, height: 1.3),
          ),
        ],
      ),
    );
  }
}
