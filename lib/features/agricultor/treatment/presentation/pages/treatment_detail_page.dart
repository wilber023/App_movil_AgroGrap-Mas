// =============================================================================
// Feature: Treatment -- Detalle del Tratamiento
// =============================================================================
// Capa: Presentation / Pages
// Pantalla nueva de solo lectura + acciones ya existentes (marcar paso
// completo / reprogramar). No agrega Bloc, Repository, Datasource ni
// UseCases: reutiliza el mismo TreatmentBloc ya provisto en main.dart y los
// mismos eventos que ya usa la vista de lista (treatment_page.dart).
//
// Recibe el TreatmentEntity ya cargado (evita una llamada de red/Hive
// adicional) y se subscribe al TreatmentBloc para mantenerse actualizada:
// si el usuario marca un paso completo o reprograma desde aqui, el Bloc
// recarga la agenda completa (igual que ya hacia antes) y esta pantalla
// vuelve a leer el tratamiento actualizado por id desde el nuevo estado.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/treatment_entity.dart';
import '../bloc/treatment_bloc.dart';

// ---------------------------------------------------------------------------
// Helpers de formato y color (puramente visuales). Se duplican de forma
// deliberada en vez de importarlos desde treatment_page.dart (donde son
// privados a esa libreria) para no modificar ese archivo, ya verificado.
// ---------------------------------------------------------------------------

const _monthsShort = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

const _monthsLong = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String _fmtShort(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]}';
String _fmtLong(DateTime d) =>
    '${d.day} de ${_monthsLong[d.month - 1]} ${d.year}';

String _relativeDayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = target.difference(today).inDays;

  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  if (diff == -1) return 'Ayer';
  if (diff > 1) return diff <= 30 ? 'En $diff días' : _fmtShort(date);
  return 'Hace ${-diff} días';
}

// Misma paleta de identidad que usa la lista (treatment_page.dart), para
// que cada tratamiento se vea con el mismo color/icono en ambas pantallas.
// Determinista por id: no es aleatorio, no se guarda nada nuevo. "Vencido"
// siempre prevalece porque es una señal de urgencia real.
const _agendaPalette = [
  AppColors.burntOrange,
  AppColors.forestGreen,
  AppColors.agendaIndigo,
  AppColors.infoBlue,
];

const _agendaIconPalette = [
  Icons.wb_sunny_rounded,
  Icons.eco_rounded,
  Icons.spa_rounded,
  Icons.water_drop_rounded,
];

Color _accentColor(TreatmentEntity t) {
  if (t.activeStep == null) return AppColors.forestGreen;
  if (t.isOverdue) return AppColors.error;
  return _agendaPalette[t.id.hashCode.abs() % _agendaPalette.length];
}

IconData _cardIcon(TreatmentEntity t) {
  if (t.activeStep == null) return Icons.check_circle_outline_rounded;
  if (t.isOverdue) return Icons.error_outline_rounded;
  return _agendaIconPalette[t.id.hashCode.abs() % _agendaIconPalette.length];
}

String _headerStatusLabel(TreatmentEntity t) {
  if (t.activeStep == null) return 'Completo';
  if (t.isOverdue) return 'Vencido';
  return 'En curso';
}

// =============================================================================
// Pantalla
// =============================================================================

class TreatmentDetailPage extends StatelessWidget {
  final TreatmentEntity treatment;
  const TreatmentDetailPage({super.key, required this.treatment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: Text(
          'Detalle del tratamiento',
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.xxlPlus),
            child: Icon(Icons.eco_rounded, color: AppColors.forestGreen),
          ),
        ],
      ),
      body: BlocBuilder<TreatmentBloc, TreatmentState>(
        builder: (context, state) {
          // Si el Bloc ya recargo la agenda (ej. tras marcar un paso
          // completo desde esta misma pantalla), se usa la version mas
          // fresca del mismo tratamiento; si no, se usa la que llego por
          // parametro al navegar aqui.
          //
          // Nota: se evita firstWhere(orElse:) a proposito. La lista real
          // detras de `state.treatments` es un List<TreatmentModel> (el
          // subtipo que arma el datasource), aunque el campo este tipado
          // como List<TreatmentEntity>. En Dart, firstWhere() usa el tipo
          // generico real de la lista en tiempo de ejecucion, asi que un
          // `orElse: () => treatment` (tipado TreatmentEntity) lanza
          // TypeError en runtime pese a compilar sin errores. Un bucle
          // manual no tiene ese problema.
          TreatmentEntity current = treatment;
          if (state is TreatmentAgendaLoaded) {
            for (final t in state.treatments) {
              if (t.id == treatment.id) {
                current = t;
                break;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.xxlPlus, AppSpacing.xxlPlus, AppSpacing.xhuge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailHeaderCard(treatment: current),
                const SizedBox(height: AppSpacing.hugePlus),
                Text(
                  'Plan de tratamiento',
                  style: AppTypography.tituloMd.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                for (int i = 0; i < current.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    child: _DetailStepCard(
                      step: current.steps[i],
                      isLast: i == current.steps.length - 1,
                      isImmediateNext: _isImmediateNext(current, i),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                _DetailActionBar(treatment: current),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Puramente de presentacion: el paso "próximo" es el inmediatamente
  /// siguiente al activo en el orden ya existente de la lista, no un campo
  /// nuevo del dominio.
  bool _isImmediateNext(TreatmentEntity t, int index) {
    final activeIndex = t.steps.indexWhere((s) => s.isScheduled);
    if (activeIndex == -1) return false;
    return index == activeIndex + 1;
  }
}

// =============================================================================
// Encabezado
// =============================================================================

class _DetailHeaderCard extends StatelessWidget {
  final TreatmentEntity treatment;
  const _DetailHeaderCard({required this.treatment});

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(treatment);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Icon(
                  _cardIcon(treatment),
                  color: accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treatment.diseaseName,
                      style: AppTypography.tituloMd.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(Icons.eco_outlined,
                            size: 14, color: AppColors.forestGreen),
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
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.mdLg),
                ),
                child: Text(
                  _headerStatusLabel(treatment),
                  style: AppTypography.etiquetaSm.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxlPlus),
          const Divider(height: 1, thickness: 0.5, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.xl),
          _InfoRow(label: 'Iniciado', value: _fmtLong(treatment.createdAt)),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Total de pasos', value: '${treatment.totalSteps}'),
        ],
      ),
    );
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
        Text(
          label,
          style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        Text(
          value,
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Paso del plan de tratamiento
// =============================================================================

class _DetailStepCard extends StatelessWidget {
  final TreatmentStepEntity step;
  final bool isLast;
  final bool isImmediateNext;

  const _DetailStepCard({
    required this.step,
    required this.isLast,
    required this.isImmediateNext,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIndicatorColumn(),
          const SizedBox(width: AppSpacing.xl),
          Expanded(child: _buildCard()),
        ],
      ),
    );
  }

  Widget _buildIndicatorColumn() {
    return SizedBox(
      width: 32,
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
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.statusHealthyBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: AppColors.forestGreen, size: 18),
      );
    }
    if (step.isOverdue) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.error, width: 2),
        ),
        child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
      );
    }
    if (step.isScheduled) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: AppColors.forestGreen, shape: BoxShape.circle),
        child: Center(
          child: Text(
            '${step.stepNumber}',
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant, width: 1.5),
      ),
      child: Center(
        child: Text(
          '${step.stepNumber}',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  step.title,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    decoration:
                        step.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                step.isCompleted && step.completedDate != null
                    ? _fmtShort(step.completedDate!)
                    : _relativeDayLabel(step.scheduledDate),
                style: AppTypography.etiquetaSm.copyWith(
                  color: step.isOverdue ? AppColors.error : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            _fmtShort(step.scheduledDate),
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: _boxColor().withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.lgXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildStatusChip(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _boxColor() {
    if (step.isCompleted) return AppColors.forestGreen;
    if (step.isOverdue) return AppColors.error;
    if (step.isScheduled) return AppColors.forestGreen;
    return AppColors.outline;
  }

  Widget _buildStatusChip() {
    final String label;
    final Color color;
    if (step.isCompleted) {
      label = 'Completado';
      color = AppColors.forestGreen;
    } else if (step.isOverdue) {
      label = 'Vencido';
      color = AppColors.error;
    } else if (step.isScheduled) {
      label = 'Programado';
      color = AppColors.forestGreen;
    } else if (isImmediateNext) {
      label = 'Próximo';
      color = AppColors.infoBlue;
    } else {
      label = 'Pendiente';
      color = AppColors.onSurfaceVariant;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          step.isCompleted ? Icons.check_circle_rounded : Icons.circle,
          size: 10,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.etiquetaSm.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Barra de acciones (actua sobre el paso activo, mismos eventos de siempre)
// =============================================================================

class _DetailActionBar extends StatelessWidget {
  final TreatmentEntity treatment;
  const _DetailActionBar({required this.treatment});

  @override
  Widget build(BuildContext context) {
    final activeStep = treatment.activeStep;

    if (activeStep == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.statusHealthyBg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.forestGreen, size: 18),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Tratamiento completado',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => _editDates(context, activeStep),
              icon: const Icon(Icons.event_repeat_rounded, size: 17),
              label: const Text('Editar fechas'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.forestGreen,
                side: const BorderSide(color: AppColors.forestGreen),
                textStyle: AppTypography.etiquetaSm.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lgXl),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => _markComplete(context, activeStep),
              icon: const Icon(Icons.check_rounded, size: 17),
              label: const Text('Marcar completo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: AppColors.white,
                textStyle: AppTypography.etiquetaSm.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lgXl),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _markComplete(BuildContext context, TreatmentStepEntity activeStep) {
    context.read<TreatmentBloc>().add(
          TreatmentStepCompleted(
            treatmentId: treatment.id,
            stepId: activeStep.id,
          ),
        );
  }

  Future<void> _editDates(
    BuildContext context,
    TreatmentStepEntity activeStep,
  ) async {
    final bloc = context.read<TreatmentBloc>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate =
        activeStep.scheduledDate.isBefore(today) ? today : activeStep.scheduledDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Nueva fecha',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (picked == null || !context.mounted) return;

    bloc.add(
      TreatmentStepRescheduled(
        treatmentId: treatment.id,
        stepId: activeStep.id,
        newDate: picked,
      ),
    );
  }
}
