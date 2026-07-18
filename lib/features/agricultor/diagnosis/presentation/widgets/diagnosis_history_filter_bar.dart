import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Barra de filtros horizontal ("Todos", "Con alerta", ...) de
/// [DiagnosisHistoryFullPage].
class DiagnosisHistoryFilterBar extends StatelessWidget {
  const DiagnosisHistoryFilterBar({
    super.key,
    required this.filters,
    required this.activeFilter,
    required this.onFilterSelected,
  });

  final List<String> filters;
  final String activeFilter;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        border: Border(
          bottom: BorderSide(
            color: AppColors.parcelsBorderLight.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        height: 32,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          itemBuilder: (context, i) {
            final filterName = filters[i];
            final isSelected = filterName == activeFilter;
            return GestureDetector(
              onTap: () => onFilterSelected(filterName),
              child: Container(
                margin: const EdgeInsets.only(right: AppSpacing.md),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.forestGreen
                      : AppColors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                ),
                child: Text(
                  filterName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.onPrimary
                        : AppColors.parcelsTextSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
