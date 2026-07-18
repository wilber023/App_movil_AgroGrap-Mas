import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/services/notification_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/treatment_entity.dart';
import '../bloc/treatment_bloc.dart';
import '../pages/treatment_detail_page.dart';
import 'treatment_agenda_helpers.dart';
import 'treatment_timeline_step.dart';

/// Tarjeta de tratamiento individual en la Agenda Agronómica: encabezado,
/// chip de diagnóstico IA, barra de progreso, toggle de recordatorios y
/// (si aplica) el timeline de pasos expandible.
class TreatmentCard extends StatefulWidget {
  final TreatmentEntity treatment;
  const TreatmentCard({super.key, required this.treatment});

  @override
  State<TreatmentCard> createState() => _TreatmentCardState();
}

class _TreatmentCardState extends State<TreatmentCard> {
  // Los tratamientos activos arrancan expandidos (es lo que hay que hacer);
  // los ya completados arrancan colapsados para no competir por atencion
  // visual con lo urgente. El usuario puede alternar libremente.
  late bool _timelineExpanded;

  TreatmentEntity get treatment => widget.treatment;

  @override
  void initState() {
    super.initState();
    _timelineExpanded = treatment.activeStep != null;
  }

  @override
  Widget build(BuildContext context) {
    final accent = agendaAccentColor(treatment);
    final isDone = treatment.activeStep == null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TreatmentDetailPage(treatment: treatment),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra de prioridad: primer elemento que el ojo detecta.
                Container(width: 5, color: accent),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(accent),
                      if (treatment.llmDiagnostico.isNotEmpty) _buildDiagnosticoChip(),
                      _buildProgressBar(accent),
                      _buildRemindersToggle(context),
                      const Divider(height: 1, thickness: 0.5),
                      if (isDone) _buildCollapseToggle(),
                      if (_timelineExpanded) _buildTimeline(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    final isDone = treatment.activeStep == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxlPlus, AppSpacing.xxlPlus, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lgXl),
            ),
            child: Icon(
              agendaCardIcon(treatment),
              color: accent,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  treatment.diseaseName,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      size: 13,
                      color: AppColors.forestGreen,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        treatment.cropName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.etiquetaSm.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!isDone)
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_right_alt_rounded,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          'Siguiente: ${treatment.activeStep!.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.etiquetaSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mdLg, vertical: AppSpacing.xsPlus),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.mdLg),
            ),
            child: Text(
              cardBadgeLabel(treatment),
              textAlign: TextAlign.right,
              style: AppTypography.etiquetaSm.copyWith(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticoChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.none, AppSpacing.xxlPlus, AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.mdLg),
          border: Border.all(
            color: AppColors.primaryContainer.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.psychology_outlined,
              size: 15,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                treatment.llmDiagnostico,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.etiquetaSm.copyWith(
                  color: AppColors.primary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.xs, AppSpacing.xxlPlus, AppSpacing.xxlPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paso ${treatment.completedSteps} de ${treatment.totalSteps}',
                style: AppTypography.etiquetaSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${treatment.progressPercent}% completado',
                style: AppTypography.etiquetaSm.copyWith(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: LinearProgressIndicator(
              value: treatment.progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersToggle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.none, AppSpacing.xl, AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                treatment.remindersActive
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                size: 15,
                color: treatment.remindersActive
                    ? AppColors.forestGreen
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.smMd),
              Text(
                'Recordatorios',
                style: AppTypography.etiquetaSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: treatment.remindersActive,
              activeTrackColor: AppColors.forestGreen,
              onChanged: (value) => _onToggleReminders(context, value),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onToggleReminders(BuildContext context, bool active) async {
    final bloc = context.read<TreatmentBloc>();

    if (active) {
      final granted = await NotificationService.instance.requestPermission();
      if (!context.mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Activa los permisos de notificaciones para recibir recordatorios.',
            ),
          ),
        );
        return;
      }
    }

    bloc.add(
      TreatmentRemindersToggled(treatmentId: treatment.id, active: active),
    );
  }

  Widget _buildCollapseToggle() {
    return InkWell(
      onTap: () => setState(() => _timelineExpanded = !_timelineExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _timelineExpanded ? 'Ocultar pasos' : 'Ver pasos completados',
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              _timelineExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: 16,
              color: AppColors.forestGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.xxlPlus, AppSpacing.xxlPlus, AppSpacing.xxlPlus),
      child: Column(
        children: [
          for (int i = 0; i < treatment.steps.length; i++)
            TreatmentTimelineStep(
              step: treatment.steps[i],
              treatmentId: treatment.id,
              isLast: i == treatment.steps.length - 1,
            ),
        ],
      ),
    );
  }
}
