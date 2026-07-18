import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../cultivo/domain/entities/crop_activity_entity.dart';
import '../../../diagnostico/presentation/pages/diagnosis_camera_aprendiz_page.dart';

/// Bottom sheet de inspección pendiente de [AprendizHomePage] (funcionalidad
/// conservada tal cual).
class InspectionBottomSheet extends StatelessWidget {
  final CropActivityEntity activity;
  final VoidCallback onPostpone;

  const InspectionBottomSheet({super.key, required this.activity, required this.onPostpone});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xhuge)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.aOutlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxlPlus,
              AppSpacing.xhuge,
              AppSpacing.xxlPlus,
              AppSpacing.giant,
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(color: AppColors.aPrimaryFixed, shape: BoxShape.circle),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.aSurfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.aPrimaryFixed),
                        boxShadow: [
                          BoxShadow(color: AppColors.aPrimaryFixed.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.eco, color: AppColors.aPrimaryContainer, size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxlPlus),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.aSecondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.aOnSecondaryContainer),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Semana ${activity.weekNumber} · Inspección programada',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.aOnSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.05,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxlPlus),
                const Text(
                  'Es momento de inspeccionar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Toma una foto de tus plantas para que el modelo de IA analice su estado actual.',
                  style: TextStyle(fontSize: 15, color: AppColors.aOnSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xhuge),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiagnosisCameraAprendizPage(
                            weekNumber: activity.weekNumber,
                            activityId: activity.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, color: AppColors.aOnPrimary, size: 18),
                    label: const Text(
                      'IR A DIAGNÓSTICO',
                      style: TextStyle(
                        color: AppColors.aOnPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.05,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.aOrangeAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mdLg)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onPostpone();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.aSecondary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mdLg)),
                    ),
                    child: const Text(
                      'POSPONER PARA MAÑANA',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.aSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
