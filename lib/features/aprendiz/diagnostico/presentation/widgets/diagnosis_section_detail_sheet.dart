import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'diagnosis_section_item.dart';

/// Abre [item] en una experiencia inmersiva (~88% de la pantalla) con
/// animación de entrada suave y Hero desde su tarjeta resumen en el
/// carrusel. Espacio en blanco amplio, título grande y contenido
/// desplazable para que la lectura se sienta cómoda, no abrumadora.
Future<void> showDiagnosisSectionDetail(BuildContext context, DiagnosisSectionItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.aOnSurface.withValues(alpha: 0.45),
    builder: (context) => _DiagnosisSectionDetailSheet(item: item),
  );
}

class _DiagnosisSectionDetailSheet extends StatelessWidget {
  final DiagnosisSectionItem item;
  const _DiagnosisSectionDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Container(
      height: screenHeight * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xhuge)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.aOutlineVariant, borderRadius: BorderRadius.circular(AppRadius.xs)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.xxl, AppSpacing.xl, AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Hero(
                  tag: 'diagnosis-section-icon-${item.id}',
                  child: Material(
                    color: AppColors.transparent,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: item.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(item.icon, color: item.accent, size: 26),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTypography.headlineMd.copyWith(fontSize: 22, color: AppColors.aOnSurface),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.aOnSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.aOutlineVariant),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xxlPlus,
                AppSpacing.xxl,
                AppSpacing.xxlPlus,
                AppSpacing.xxhuge + bottomSafe,
              ),
              child: item.expandedBuilder(context),
            ),
          ),
        ],
      ),
    );
  }
}
