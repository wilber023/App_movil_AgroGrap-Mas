import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/treatment_entity.dart';
import '../bloc/treatment_bloc.dart';

// ---------------------------------------------------------------------------

const _months = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
String _fmtShort(DateTime d) => '${d.day} ${_months[d.month - 1]}';

class TreatmentPage extends StatelessWidget {
  const TreatmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Agenda Agronómica',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<TreatmentBloc>().add(const TreatmentAgendaRequested()),
          ),
        ],
      ),
      body: BlocBuilder<TreatmentBloc, TreatmentState>(
        builder: (context, state) {
          if (state is TreatmentInitial || state is TreatmentLoading) {
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
            if (state.treatments.isEmpty) return const _EmptyView();
            return _AgendaListView(treatments: state.treatments);
          }
          // TreatmentStepMarked — momentaneamente vacío mientras recarga
          return const Center(
            child: CircularProgressIndicator(color: AppColors.forestGreen),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Lista de tratamientos
// =============================================================================

class _AgendaListView extends StatelessWidget {
  final List<TreatmentEntity> treatments;
  const _AgendaListView({required this.treatments});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.forestGreen,
      onRefresh: () async {
        context.read<TreatmentBloc>().add(const TreatmentAgendaRequested());
        // Espera a que el estado cambie
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: treatments.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _TreatmentCard(treatment: treatments[index]),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Tarjeta de tratamiento individual
// =============================================================================

class _TreatmentCard extends StatelessWidget {
  final TreatmentEntity treatment;
  const _TreatmentCard({required this.treatment});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          if (treatment.llmDiagnostico.isNotEmpty) _buildDiagnosticoChip(),
          _buildProgressBar(),
          const Divider(height: 1, thickness: 0.5),
          _buildTimeline(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.burntOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bug_report_outlined,
              color: AppColors.burntOrange,
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
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      size: 13,
                      color: AppColors.forestGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      treatment.cropName,
                      style: AppTypography.etiquetaSm.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _fmtDate(treatment.createdAt),
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: treatment.progressPercent == 100
                  ? AppColors.statusHealthyBg
                  : AppColors.warmAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              treatment.progressPercent == 100 ? 'COMPLETO' : 'ACTIVO',
              style: AppTypography.etiquetaSm.copyWith(
                color: treatment.progressPercent == 100
                    ? AppColors.forestGreen
                    : AppColors.burntOrange,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticoChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryContainer.withValues(alpha: 0.4),
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
            const SizedBox(width: 8),
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

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: treatment.progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          for (int i = 0; i < treatment.steps.length; i++)
            _TimelineStep(
              step: treatment.steps[i],
              treatmentId: treatment.id,
              isLast: i == treatment.steps.length - 1,
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Paso de la línea de tiempo
// =============================================================================

class _TimelineStep extends StatelessWidget {
  final TreatmentStepEntity step;
  final String treatmentId;
  final bool isLast;

  const _TimelineStep({
    required this.step,
    required this.treatmentId,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIndicatorColumn(),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorColumn() {
    return SizedBox(
      width: 28,
      child: Column(
        children: [
          _buildCircle(),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                color: step.isCompleted
                    ? AppColors.forestGreen.withValues(alpha: 0.4)
                    : AppColors.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircle() {
    if (step.isCompleted) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.statusHealthyBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: AppColors.forestGreen, size: 16),
      );
    }
    if (step.isScheduled) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.warmAmber.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.burntOrange, width: 2),
        ),
        child: const Icon(Icons.schedule_rounded, color: AppColors.burntOrange, size: 14),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant, width: 1.5),
      ),
      child: Center(
        child: Text(
          step.stepNumber.toString(),
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                step.title,
                style: AppTypography.labelMd.copyWith(
                  color: step.isCompleted
                      ? AppColors.onSurfaceVariant
                      : AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                  decoration:
                      step.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            _buildStatusChip(),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 12, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              step.isCompleted && step.completedDate != null
                  ? 'Completado ${_fmtShort(step.completedDate!)}'
                  : _fmtDate(step.scheduledDate),
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          step.description,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        if (step.isScheduled) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ElevatedButton.icon(
              onPressed: () => _markComplete(context),
              icon: const Icon(Icons.check_rounded, size: 15),
              label: const Text('Marcar completado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: Colors.white,
                textStyle: AppTypography.etiquetaSm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip() {
    if (step.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.statusHealthyBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'completado',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.forestGreen,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      );
    }
    if (step.isScheduled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warmAmber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'pendiente',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.burntOrange,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'programado',
        style: AppTypography.etiquetaSm.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }

  void _markComplete(BuildContext context) {
    context.read<TreatmentBloc>().add(
          TreatmentStepCompleted(
            treatmentId: treatmentId,
            stepId: step.id,
          ),
        );
  }
}

// =============================================================================
// Estados vacío / error
// =============================================================================

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_outlined,
                size: 40,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin tratamientos activos',
              style: AppTypography.tituloMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Realiza un diagnóstico de tu cultivo.\nCuando se detecte una enfermedad, aparecerá\naquí un plan de tratamiento automático.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.offlineGrey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
