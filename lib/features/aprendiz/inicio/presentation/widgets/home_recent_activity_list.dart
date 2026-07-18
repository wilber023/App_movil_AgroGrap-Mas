import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/recent_activity_item_entity.dart';

/// Lista de actividad reciente (maximo tres elementos, ya acotado por el
/// repositorio): combina el diagnostico, el registro de cultivo y la
/// actividad completada mas recientes, sin inventar eventos.
class HomeRecentActivityList extends StatelessWidget {
  final List<RecentActivityItemEntity> items;

  const HomeRecentActivityList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad reciente',
          style: AppTypography.agendaSectionTitle.copyWith(fontSize: 16, color: AppColors.aPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          Text(
            'Aún no hay actividad reciente.',
            style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
          )
        else
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return _RecentActivityTile(item: entry.value, isLast: isLast);
          }),
      ],
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  final RecentActivityItemEntity item;
  final bool isLast;

  const _RecentActivityTile({required this.item, required this.isLast});

  Color get _color {
    switch (item.type) {
      case RecentActivityType.diagnosis:
        return AppColors.aOnPrimaryFixedVariant;
      case RecentActivityType.cropRegistered:
        return AppColors.aSecondary;
      case RecentActivityType.activityCompleted:
        return AppColors.aOrange;
    }
  }

  String _relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return 'Hace ${diff.inDays} día${diff.inDays == 1 ? '' : 's'}';
    if (diff.inHours >= 1) return 'Hace ${diff.inHours} hora${diff.inHours == 1 ? '' : 's'}';
    return 'Hace instantes';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? AppSpacing.none : AppSpacing.xxlPlus),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.aMint, width: 2),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 32,
                  color: AppColors.aSurfaceVariant,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _relative(item.date),
                  style: AppTypography.etiquetaBold.copyWith(fontSize: 11, color: _color, letterSpacing: 0.5),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.label,
                  style: AppTypography.agendaBody.copyWith(
                    fontSize: 15,
                    color: AppColors.aPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.detail != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    item.detail!,
                    style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
