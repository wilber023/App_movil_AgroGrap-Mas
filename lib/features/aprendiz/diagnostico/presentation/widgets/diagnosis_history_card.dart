import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../agricultor/diagnosis/domain/entities/diagnosis_entity.dart';

const String _kFont = 'Inter';

final List<BoxShadow> kAprendizCardShadow = [
  BoxShadow(color: AppColors.aOnSurface.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
];

/// Card de un diagnóstico dentro de "Mis diagnósticos": miniatura, enfermedad,
/// cultivo, estado y fecha. Widget puro — no conoce el cubit ni la navegación,
/// solo recibe los datos y un callback `onTap`.
class DiagnosisHistoryCard extends StatelessWidget {
  final DiagnosisEntity diagnosis;
  final VoidCallback onTap;

  const DiagnosisHistoryCard({
    super.key,
    required this.diagnosis,
    required this.onTap,
  });

  String _fmtDate(DateTime d) {
    const m = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final d = diagnosis;
    final isHealthy = d.statusLabel == 'Saludable';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.aSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.aOutlineVariant),
          boxShadow: kAprendizCardShadow,
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.mdLg),
              child: d.imagePath != null && File(d.imagePath!).existsSync()
                  ? Image.file(File(d.imagePath!), width: 60, height: 60, fit: BoxFit.cover)
                  : Container(
                      width: 60, height: 60,
                      color: AppColors.aSurfaceContainerHigh,
                      child: const Icon(Icons.eco_outlined, color: AppColors.aOnSurfaceVariant),
                    ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.diseaseName,
                    style: const TextStyle(fontFamily: _kFont, fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    d.cropName,
                    style: const TextStyle(fontFamily: _kFont, fontSize: 12, color: AppColors.aOnSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.smMd),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xxsPlus,
                        ),
                        decoration: BoxDecoration(
                          color: isHealthy ? AppColors.aSecondaryContainer : AppColors.aDiseaseCardBg,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          d.statusLabel,
                          style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isHealthy ? AppColors.aOnSecondaryContainer : AppColors.aDiseaseCardText,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _fmtDate(d.diagnosedAt),
                        style: const TextStyle(fontFamily: _kFont, fontSize: 11, color: AppColors.aOnSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right_rounded, color: AppColors.aOnSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}
