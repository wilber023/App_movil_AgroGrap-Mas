import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../parcels/domain/entities/parcel_entity.dart';
import '../../../parcels/presentation/bloc/parcel_bloc.dart';
import '../../../treatment/domain/entities/treatment_entity.dart';
import '../../../treatment/presentation/bloc/treatment_bloc.dart';
import 'home_helpers.dart';
import 'home_section_header.dart';

/// Sección "Cultivos activos" de HomePage: tarjetas horizontales por
/// parcela, con estado de salud y próxima tarea/último análisis.
class HomeActiveCropsSection extends StatelessWidget {
  const HomeActiveCropsSection({super.key, required this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParcelBloc, ParcelState>(
      builder: (context, parcelState) {
        final parcels = parcelState is ParcelLoaded ? parcelState.parcels : const <ParcelEntity>[];
        final isLoading = parcelState is ParcelLoading || parcelState is ParcelInitial;
        final treatmentState = context.watch<TreatmentBloc>().state;
        final treatments = treatmentState is TreatmentAgendaLoaded
            ? treatmentState.treatments
            : const <TreatmentEntity>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionHeader(
              title: 'Cultivos activos',
              action: parcels.isEmpty ? null : 'Ver todos',
              onTap: () => onNavigateToTab?.call(2),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (isLoading)
              const SizedBox(
                height: 80,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
                  ),
                ),
              )
            else if (parcels.isEmpty)
              _buildEmptyParcels()
            else
              SizedBox(
                height: 176,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: parcels.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xl),
                  itemBuilder: (_, i) => _CropCard(
                    parcel: parcels[i],
                    treatments: treatments,
                    onTap: () => onNavigateToTab?.call(2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyParcels() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.homeEmptyIconBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_florist_outlined, color: AppColors.homeEmptyIconFg, size: 18),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aún no tienes parcelas',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Registra tu primer cultivo en la pestaña Mis Parcelas',
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
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

class _CropCard extends StatelessWidget {
  final ParcelEntity parcel;
  final List<TreatmentEntity> treatments;
  final VoidCallback onTap;
  const _CropCard({required this.parcel, required this.treatments, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusInfo = homeParcelStatusInfo(parcel.status);
    final tier = homeParcelStatusTier(parcel.status);

    // Mejor esfuerzo: no existe un vinculo real parcela<->tratamiento en el
    // dominio (TreatmentEntity solo guarda el nombre del cultivo, no un
    // parcelId), asi que se empareja por nombre de cultivo. Si el
    // agricultor tiene 2 parcelas del mismo cultivo, ambas mostrarian la
    // misma tarea — limitacion conocida, no se oculta.
    TreatmentEntity? match;
    for (final t in treatments) {
      if (t.cropName.toLowerCase() == parcel.cropName.toLowerCase() && t.activeStep != null) {
        match = t;
        break;
      }
    }

    final String actionLabel;
    final String actionValue;
    if (match != null) {
      actionLabel = match.isOverdue ? 'Tarea vencida' : 'Próxima tarea';
      actionValue = match.isOverdue
          ? 'hace ${match.activeStep!.daysOverdue} día${match.activeStep!.daysOverdue == 1 ? '' : 's'}'
          : (match.isDueToday ? 'Hoy' : match.activeStep!.title);
    } else if (parcel.lastDiagnosisAt != null) {
      actionLabel = 'Último análisis';
      actionValue = homeTimeAgo(parcel.lastDiagnosisAt!);
    } else {
      actionLabel = 'Sin diagnóstico';
      actionValue = 'Aún no analizado';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 172,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.onPrimary,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border(left: BorderSide(color: statusInfo.color, width: 3)),
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.mdLg),
                  ),
                  child: Icon(homeCropIcon(parcel.cropName), color: statusInfo.color, size: 18),
                ),
                const Spacer(),
                if (tier != null)
                  _MiniRing(percent: tier, color: statusInfo.color),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              parcel.cropName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
            ),
            Text(
              parcel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxsPlus),
              decoration: BoxDecoration(
                color: statusInfo.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                statusInfo.label,
                style: AppTypography.etiquetaSm.copyWith(
                  color: statusInfo.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            const Spacer(),
            const Divider(height: AppSpacing.xxl, thickness: 0.5),
            Text(
              actionLabel,
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 9.5),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    actionValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.etiquetaSm.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Anillo circular pequeño. El numero es la representacion estilizada de
/// [homeParcelStatusTier], no una medicion — ver esa funcion para el porque.
class _MiniRing extends StatelessWidget {
  final int percent;
  final Color color;
  const _MiniRing({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 3,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '$percent',
            style: AppTypography.etiquetaSm.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
