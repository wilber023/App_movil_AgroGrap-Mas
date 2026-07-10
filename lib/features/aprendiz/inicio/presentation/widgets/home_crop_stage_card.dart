import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/crop_status_summary_entity.dart';

/// Tarjeta "Tu cultivo actual": nombre + etapa real + linea de progreso de
/// etapas. La secuencia de 5 etapas es una escala generica de crecimiento
/// (no datos inventados del cultivo): solo ubica visualmente la etapa real
/// que reporta el backend (`stageLabel`) dentro de esa escala.
class HomeCropStageCard extends StatelessWidget {
  final CropStatusSummaryEntity status;
  final VoidCallback onViewDetails;

  const HomeCropStageCard({super.key, required this.status, required this.onViewDetails});

  static const _stageLabels = ['Siembra', 'Crecimiento', 'Floración', 'Fruto', 'Cosecha'];

  @override
  Widget build(BuildContext context) {
    if (!status.hasCropPlan) return const SizedBox.shrink();

    final stageIndex = status.stageIndex ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tu cultivo actual',
                style: AppTypography.agendaSectionTitle.copyWith(fontSize: 15, color: AppColors.aPrimary),
              ),
              GestureDetector(
                onTap: onViewDetails,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver detalles', style: AppTypography.etiquetaBold.copyWith(color: AppColors.aSecondary)),
                    const Icon(Icons.arrow_forward, size: 14, color: AppColors.aSecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.aMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco, color: AppColors.aSecondary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.cropName ?? '',
                      style: AppTypography.agendaTitle.copyWith(fontSize: 17, color: AppColors.aPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Etapa actual',
                      style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnSurfaceVariant),
                    ),
                    Text(
                      status.stageLabel ?? '',
                      style: AppTypography.etiquetaBold.copyWith(color: AppColors.aSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StageStepper(currentIndex: stageIndex, labels: _stageLabels),
          const SizedBox(height: 14),
          _InfoRow(label: 'Diagnóstico más reciente', value: status.lastDiagnosisLabel ?? 'Sin novedades'),
          const SizedBox(height: 6),
          _InfoRow(
            label: 'Última actualización',
            value: status.lastUpdate != null ? _relativeDate(status.lastUpdate!) : 'Sin diagnósticos aún',
          ),
        ],
      ),
    );
  }

  String _relativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return 'Hace ${diff.inDays} día${diff.inDays == 1 ? '' : 's'}';
    if (diff.inHours >= 1) return 'Hace ${diff.inHours} hora${diff.inHours == 1 ? '' : 's'}';
    return 'Hace instantes';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.agendaBody.copyWith(color: AppColors.aPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _StageStepper extends StatelessWidget {
  final int currentIndex;
  final List<String> labels;

  const _StageStepper({required this.currentIndex, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= currentIndex ? AppColors.aSecondary : AppColors.aOutlineVariant,
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= currentIndex ? AppColors.aSecondary : AppColors.aSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: AppTypography.etiquetaSm.copyWith(
                  fontSize: 9,
                  color: i == currentIndex ? AppColors.aSecondary : AppColors.aOnSurfaceVariant,
                  fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
