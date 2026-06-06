import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/shared_components.dart';
import '../../domain/entities/treatment_entity.dart';
import '../bloc/treatment_bloc.dart';

// Pantalla de Agenda de Tratamiento (Stitch: "Agenda de Tratamiento")
// Header con enfermedad, barra de progreso, toggle de recordatorios,
// timeline vertical de pasos.

class TreatmentAgendaPage extends StatelessWidget {
  const TreatmentAgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TreatmentBloc, TreatmentState>(
      builder: (context, state) {
        if (state is TreatmentLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.forestGreen),
          );
        }
        if (state is TreatmentFailure) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context
                .read<TreatmentBloc>()
                .add(const TreatmentAgendaRequested()),
          );
        }
        if (state is TreatmentAgendaLoaded) {
          if (state.treatments.isEmpty) {
            return const _EmptyView();
          }
          return _AgendaContent(treatments: state.treatments);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _AgendaContent extends StatelessWidget {
  final List<TreatmentEntity> treatments;
  const _AgendaContent({required this.treatments});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agenda de Tratamiento',
            style: AppTypography.tituloLg.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            '${treatments.length} tratamientos activos',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ...treatments
              .map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _TreatmentCard(treatment: t),
                  )),
        ],
      ),
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  final TreatmentEntity treatment;
  const _TreatmentCard({required this.treatment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: enfermedad + badge
          _buildHeader(),
          const SizedBox(height: 16),
          // Barra de progreso
          _buildProgressSection(),
          const SizedBox(height: 12),
          // Toggle de recordatorios
          _buildRemindersToggle(),
          const SizedBox(height: 16),
          const Divider(color: AppColors.outlineVariant, height: 1),
          const SizedBox(height: 16),
          // Timeline de pasos
          _buildTimeline(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.medical_services_outlined,
            color: AppColors.forestGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                treatment.diseaseName,
                style: AppTypography.tituloMd
                    .copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 2),
              Text(
                treatment.cropName,
                style: AppTypography.etiquetaSm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        StatusPill(
          label: 'Activo',
          background: AppColors.statusHealthyBg,
          textColor: AppColors.statusHealthyText,
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Paso ${treatment.completedSteps} de ${treatment.totalSteps}',
              style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
            ),
            Text(
              '${treatment.progressPercent}% completado',
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppProgressBar(value: treatment.progress, color: AppColors.forestGreen),
      ],
    );
  }

  Widget _buildRemindersToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.notifications_active_outlined,
                size: 18, color: AppColors.forestGreen),
            const SizedBox(width: 8),
            Text(
              'Recordatorios activos',
              style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
            ),
          ],
        ),
        Switch.adaptive(
          value: treatment.remindersActive,
          activeTrackColor: AppColors.forestGreen,
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return Column(
      children: treatment.steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == treatment.steps.length - 1;

        return _TimelineStep(
          step: step,
          isLast: isLast,
          treatmentId: treatment.id,
        );
      }).toList(),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final TreatmentStepEntity step;
  final bool isLast;
  final String treatmentId;

  const _TimelineStep({
    required this.step,
    required this.isLast,
    required this.treatmentId,
  });

  @override
  Widget build(BuildContext context) {
    final Color indicatorColor;
    final IconData indicatorIcon;

    if (step.isCompleted) {
      indicatorColor = AppColors.forestGreen;
      indicatorIcon = Icons.check_rounded;
    } else if (step.isScheduled) {
      indicatorColor = AppColors.warmAmber;
      indicatorIcon = Icons.schedule_rounded;
    } else {
      indicatorColor = AppColors.onSurfaceVariant;
      indicatorIcon = Icons.circle_outlined;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linea vertical + indicador
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: indicatorColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: indicatorColor, width: 2),
                  ),
                  child: Icon(indicatorIcon, size: 14, color: indicatorColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.isCompleted
                          ? AppColors.forestGreen.withValues(alpha: 0.3)
                          : AppColors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Contenido del paso
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: step.isCompleted
                    ? AppColors.statusHealthyBg
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: step.isCompleted
                      ? AppColors.forestGreen.withValues(alpha: 0.2)
                      : AppColors.outlineVariant.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Paso ${step.stepNumber}: ${step.title}',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onSurface,
                            decoration: step.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      _buildStatusChip(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.description,
                    style: AppTypography.etiquetaSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(step.scheduledDate),
                        style: AppTypography.etiquetaSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  // Boton para marcar como completado
                  if (step.isScheduled) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<TreatmentBloc>().add(
                                TreatmentStepCompleted(
                                  treatmentId: treatmentId,
                                  stepId: step.id,
                                ),
                              );
                        },
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Marcar como completado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          foregroundColor: Colors.white,
                          textStyle: AppTypography.etiquetaSm
                              .copyWith(fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final String label;
    final Color bgColor;
    final Color textColor;

    if (step.isCompleted) {
      label = 'Completado';
      bgColor = AppColors.statusHealthyBg;
      textColor = AppColors.statusHealthyText;
    } else if (step.isScheduled) {
      label = 'Programado';
      bgColor = AppColors.statusAtRiskBg;
      textColor = AppColors.statusAtRiskText;
    } else {
      label = 'Pendiente';
      bgColor = AppColors.surfaceContainerLow;
      textColor = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.statusPill.copyWith(color: textColor),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded, size: 56,
                color: AppColors.forestGreen.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Sin tratamientos activos',
              style: AppTypography.tituloMd
                  .copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Los tratamientos apareceran aqui despues de un diagnostico.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56,
                color: AppColors.offlineGreyDark),
            const SizedBox(height: 16),
            Text(message, style: AppTypography.bodyMd,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
