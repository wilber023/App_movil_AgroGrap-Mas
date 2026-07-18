import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/services/notification_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/treatment_entity.dart';
import '../bloc/treatment_bloc.dart';
import 'treatment_detail_page.dart';

// =============================================================================
// Helpers de formato y de presentacion (puramente visuales).
// No contienen reglas de negocio: solo formatean o mapean a color/icono
// datos que la entidad ya expone (isOverdue, isDueToday, isDueThisWeek,
// activeStep, daysOverdue). La logica de filtros/estados vive intacta en
// TreatmentEntity/TreatmentBloc.
// =============================================================================

const _months = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

const _monthsLong = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String _fmtShort(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String _todayLabel() {
  final now = DateTime.now();
  return 'Hoy, ${now.day} de ${_monthsLong[now.month - 1]}';
}

/// Etiqueta relativa ("Hoy", "Mañana", "En 3 días", "Hace 2 días") a partir
/// de una fecha que el dominio ya calculo. Solo formatea, no decide nada.
String _relativeDayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = target.difference(today).inDays;

  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  if (diff == -1) return 'Ayer';
  if (diff > 1) return diff <= 7 ? 'En $diff días' : _fmtShort(date);
  return 'Hace ${-diff} días';
}

/// Paleta de identidad decorativa por tarjeta (variedad visual, no urgencia).
/// El color/icono de cada tratamiento se elige de forma determinista segun
/// su id, para que sea siempre el mismo entre recargas y entre la lista y
/// el detalle — no es aleatorio, no se guarda nada nuevo.
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

/// Color de identidad de la tarjeta. "Vencido" y "Completo" siempre
/// prevalecen sobre la decoracion porque son señales de urgencia reales
/// que no deben perderse por variedad visual.
Color _agendaAccentColor(TreatmentEntity t) {
  if (t.activeStep == null) return AppColors.forestGreen;
  if (t.isOverdue) return AppColors.error;
  return _agendaPalette[t.id.hashCode.abs() % _agendaPalette.length];
}

IconData _agendaCardIcon(TreatmentEntity t) {
  if (t.activeStep == null) return Icons.check_circle_outline_rounded;
  if (t.isOverdue) return Icons.error_outline_rounded;
  return _agendaIconPalette[t.id.hashCode.abs() % _agendaIconPalette.length];
}

/// Texto corto de la badge de la tarjeta: "Completo", "Vencido hace X días"
/// o la etiqueta relativa del proximo paso.
String _cardBadgeLabel(TreatmentEntity t) {
  if (t.activeStep == null) return 'Completo';
  final step = t.activeStep!;
  if (t.isOverdue) {
    final days = step.daysOverdue;
    return 'Vencido hace $days día${days == 1 ? '' : 's'}';
  }
  return _relativeDayLabel(step.scheduledDate);
}

Color _sectionColor(_AgendaSection section) {
  switch (section) {
    case _AgendaSection.vencidos:
      return AppColors.error;
    case _AgendaSection.hoy:
      return AppColors.burntOrange;
    case _AgendaSection.semana:
      return AppColors.warmAmber;
    case _AgendaSection.masAdelante:
      return AppColors.outline;
    case _AgendaSection.completados:
      return AppColors.forestGreen;
  }
}

IconData _sectionIcon(_AgendaSection section) {
  switch (section) {
    case _AgendaSection.vencidos:
      return Icons.error_outline_rounded;
    case _AgendaSection.hoy:
      return Icons.today_rounded;
    case _AgendaSection.semana:
      return Icons.date_range_rounded;
    case _AgendaSection.masAdelante:
      return Icons.schedule_rounded;
    case _AgendaSection.completados:
      return Icons.check_circle_outline_rounded;
  }
}

// =============================================================================
// Pantalla
// =============================================================================

class TreatmentPage extends StatelessWidget {
  const TreatmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Agenda Agronómica',
          style: AppTypography.tituloMd.copyWith(
            color: AppColors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.forestGreen),
            tooltip: 'Actualizar',
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

enum _AgendaFilter { todos, hoy, semana, vencidos }

// Agrupacion visual usada unicamente en el filtro "Todos" (Etapa 4). No es
// un calendario ni una pantalla nueva: es la misma lista, organizada en
// secciones con encabezado.
enum _AgendaSection { vencidos, hoy, semana, masAdelante, completados }

const _agendaSectionOrder = [
  _AgendaSection.vencidos,
  _AgendaSection.hoy,
  _AgendaSection.semana,
  _AgendaSection.masAdelante,
  _AgendaSection.completados,
];

const _agendaSectionTitles = {
  _AgendaSection.vencidos: 'Vencidos',
  _AgendaSection.hoy: 'Hoy',
  _AgendaSection.semana: 'Esta semana',
  _AgendaSection.masAdelante: 'Más adelante',
  _AgendaSection.completados: 'Completados',
};

_AgendaSection _sectionFor(TreatmentEntity t) {
  if (t.activeStep == null) return _AgendaSection.completados;
  if (t.isOverdue) return _AgendaSection.vencidos;
  if (t.isDueToday) return _AgendaSection.hoy;
  if (t.isDueThisWeek) return _AgendaSection.semana;
  return _AgendaSection.masAdelante;
}

class _AgendaListView extends StatefulWidget {
  final List<TreatmentEntity> treatments;
  const _AgendaListView({required this.treatments});

  @override
  State<_AgendaListView> createState() => _AgendaListViewState();
}

class _AgendaListViewState extends State<_AgendaListView> {
  // "Todos" por defecto: conserva el comportamiento actual sin filtrar nada.
  _AgendaFilter _filter = _AgendaFilter.todos;

  List<TreatmentEntity> get _filteredTreatments {
    switch (_filter) {
      case _AgendaFilter.todos:
        return widget.treatments;
      case _AgendaFilter.hoy:
        return widget.treatments.where((t) => t.isDueToday).toList();
      case _AgendaFilter.semana:
        return widget.treatments.where((t) => t.isDueThisWeek).toList();
      case _AgendaFilter.vencidos:
        return widget.treatments.where((t) => t.isOverdue).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTreatments;
    return RefreshIndicator(
      color: AppColors.forestGreen,
      onRefresh: () async {
        context.read<TreatmentBloc>().add(const TreatmentAgendaRequested());
        // Espera a que el estado cambie
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.xxlPlus, AppSpacing.xxlPlus, AppSpacing.xhuge),
        children: [
          _AgendaSummaryHeader(treatments: widget.treatments),
          const SizedBox(height: AppSpacing.xxxl),
          _FilterChipsRow(
            selected: _filter,
            treatments: widget.treatments,
            onSelected: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          if (filtered.isEmpty)
            const _FilteredEmptyState()
          else if (_filter == _AgendaFilter.todos)
            ..._buildGroupedSections(filtered)
          else
            ...filtered.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxlPlus),
                  child: _TreatmentCard(treatment: t),
                )),
        ],
      ),
    );
  }

  /// Agrupa por seccion preservando el orden ya calculado en [treatments]
  /// dentro de cada grupo. Solo se usa cuando el filtro activo es "Todos":
  /// los demas filtros ya representan una unica categoria.
  List<Widget> _buildGroupedSections(List<TreatmentEntity> treatments) {
    final groups = <_AgendaSection, List<TreatmentEntity>>{};
    for (final t in treatments) {
      groups.putIfAbsent(_sectionFor(t), () => []).add(t);
    }

    final widgets = <Widget>[];
    for (final section in _agendaSectionOrder) {
      final items = groups[section];
      if (items == null || items.isEmpty) continue;

      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl, top: AppSpacing.xs),
        child: _AgendaSectionHeader(section: section, count: items.length),
      ));
      widgets.addAll(items.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxlPlus),
            child: _TreatmentCard(treatment: t),
          )));
      widgets.add(const SizedBox(height: AppSpacing.lg));
    }
    return widgets;
  }
}

// =============================================================================
// Resumen del día
// =============================================================================

class _AgendaSummaryHeader extends StatelessWidget {
  final List<TreatmentEntity> treatments;
  const _AgendaSummaryHeader({required this.treatments});

  @override
  Widget build(BuildContext context) {
    final overdue = treatments.where((t) => t.isOverdue).length;
    final today = treatments.where((t) => t.isDueToday).length;
    final week = treatments.where((t) => t.isDueThisWeek).length;
    final completed = treatments.where((t) => t.activeStep == null).length;
    final allClear = overdue == 0 && today == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AgendaHeroCard(allClear: allClear),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  count: overdue,
                  label: 'Vencidas',
                  color: AppColors.error,
                  icon: Icons.error_outline_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _SummaryStat(
                  count: today,
                  label: 'Hoy',
                  color: AppColors.burntOrange,
                  icon: Icons.today_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _SummaryStat(
                  count: week,
                  label: 'Esta semana',
                  color: AppColors.forestGreen,
                  icon: Icons.date_range_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _SummaryStat(
                  count: completed,
                  label: 'Completadas',
                  color: AppColors.infoBlue,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgendaHeroCard extends StatelessWidget {
  final bool allClear;
  const _AgendaHeroCard({required this.allClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.huge, AppSpacing.huge, AppSpacing.huge, AppSpacing.huge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.forestGreen],
        ),
        borderRadius: BorderRadius.circular(AppRadius.huge),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ilustracion decorativa (hojas), semi-transparente, esquina superior derecha.
          Positioned(
            right: -18,
            top: -22,
            child: Icon(
              Icons.eco_rounded,
              size: 120,
              color: AppColors.white.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            right: 28,
            top: 6,
            child: Icon(
              Icons.eco_rounded,
              size: 46,
              color: AppColors.white.withValues(alpha: 0.16),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _todayLabel(),
                style: AppTypography.tituloMd.copyWith(
                  color: AppColors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxsPlus),
              Text(
                allClear
                    ? 'Sin pendientes urgentes. Buen trabajo.'
                    : 'Así va tu trabajo',
                style: AppTypography.etiquetaSm.copyWith(
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: AppSpacing.xxlPlus),
              GestureDetector(
                onTap: () => _showComingSoon(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Resumen semanal',
                        style: AppTypography.etiquetaSm.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('El resumen semanal estará disponible próximamente.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }
}

class _SummaryStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryStat({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: AppSpacing.xsPlus),
          Text(
            '$count',
            style: AppTypography.headlineMd.copyWith(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Chips de filtro
// =============================================================================

class _FilterChipsRow extends StatelessWidget {
  final _AgendaFilter selected;
  final List<TreatmentEntity> treatments;
  final ValueChanged<_AgendaFilter> onSelected;

  const _FilterChipsRow({
    required this.selected,
    required this.treatments,
    required this.onSelected,
  });

  static const _labels = {
    _AgendaFilter.todos: 'Todos',
    _AgendaFilter.hoy: 'Hoy',
    _AgendaFilter.semana: 'Semana',
    _AgendaFilter.vencidos: 'Vencidos',
  };

  int _countFor(_AgendaFilter f) {
    switch (f) {
      case _AgendaFilter.todos:
        return treatments.length;
      case _AgendaFilter.hoy:
        return treatments.where((t) => t.isDueToday).length;
      case _AgendaFilter.semana:
        return treatments.where((t) => t.isDueThisWeek).length;
      case _AgendaFilter.vencidos:
        return treatments.where((t) => t.isOverdue).length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _AgendaFilter.values.map((f) {
          final isSelected = f == selected;
          final isVencidos = f == _AgendaFilter.vencidos;
          final count = _countFor(f);
          final label = count > 0 ? '${_labels[f]} · $count' : _labels[f]!;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onSelected(f),
              labelStyle: AppTypography.etiquetaSm.copyWith(
                color: isSelected
                    ? AppColors.white
                    : (isVencidos && count > 0
                        ? AppColors.error
                        : AppColors.onSurfaceVariant),
                fontWeight: FontWeight.w600,
              ),
              selectedColor:
                  isVencidos ? AppColors.error : AppColors.forestGreen,
              backgroundColor: AppColors.surfaceContainerLow,
              side: BorderSide(
                color: isVencidos && count > 0 && !isSelected
                    ? AppColors.error.withValues(alpha: 0.4)
                    : AppColors.outlineVariant,
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xgiant),
      child: Center(
        child: Text(
          'No hay tratamientos en este filtro.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// =============================================================================
// Encabezado de seccion (Vencidos / Hoy / Esta semana / Más adelante / ...)
// =============================================================================

class _AgendaSectionHeader extends StatelessWidget {
  final _AgendaSection section;
  final int count;
  const _AgendaSectionHeader({required this.section, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = _sectionColor(section);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xsPlus),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(_sectionIcon(section), size: 14, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          _agendaSectionTitles[section]!,
          style: AppTypography.tituloMd.copyWith(
            color: AppColors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
          ),
          child: Text(
            '$count',
            style: AppTypography.etiquetaSm.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Tarjeta de tratamiento individual
// =============================================================================

class _TreatmentCard extends StatefulWidget {
  final TreatmentEntity treatment;
  const _TreatmentCard({required this.treatment});

  @override
  State<_TreatmentCard> createState() => _TreatmentCardState();
}

class _TreatmentCardState extends State<_TreatmentCard> {
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
    final accent = _agendaAccentColor(treatment);
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
              _agendaCardIcon(treatment),
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
              _cardBadgeLabel(treatment),
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

const _descriptionCollapseThreshold = 90;

class _TimelineStep extends StatefulWidget {
  final TreatmentStepEntity step;
  final String treatmentId;
  final bool isLast;

  const _TimelineStep({
    required this.step,
    required this.treatmentId,
    required this.isLast,
  });

  @override
  State<_TimelineStep> createState() => _TimelineStepState();
}

class _TimelineStepState extends State<_TimelineStep> {
  bool _descriptionExpanded = false;

  TreatmentStepEntity get step => widget.step;
  String get treatmentId => widget.treatmentId;
  bool get isLast => widget.isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIndicatorColumn(),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? AppSpacing.none : AppSpacing.huge),
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
    if (step.isOverdue) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.error, width: 2),
        ),
        child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 14),
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
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(
              step.isOverdue
                  ? Icons.error_outline_rounded
                  : Icons.calendar_today_outlined,
              size: 12,
              color: step.isOverdue ? AppColors.error : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                step.isOverdue
                    ? 'Atrasado ${step.daysOverdue} día${step.daysOverdue == 1 ? '' : 's'} '
                        '(${_fmtShort(step.scheduledDate)})'
                    : (step.isCompleted && step.completedDate != null
                        ? 'Completado ${_fmtShort(step.completedDate!)}'
                        : '${_relativeDayLabel(step.scheduledDate)} · ${_fmtShort(step.scheduledDate)}'),
                style: AppTypography.etiquetaSm.copyWith(
                  color: step.isOverdue ? AppColors.error : AppColors.onSurfaceVariant,
                  fontWeight: step.isOverdue ? FontWeight.w600 : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          step.description,
          maxLines: _descriptionExpanded ? null : 2,
          overflow: _descriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        if (step.description.length > _descriptionCollapseThreshold)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _descriptionExpanded = !_descriptionExpanded),
              child: Text(
                _descriptionExpanded ? 'Ver menos' : 'Ver más',
                style: AppTypography.etiquetaSm.copyWith(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        if (step.isScheduled) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: () => _markComplete(context),
                    icon: const Icon(Icons.check_rounded, size: 15),
                    label: const Text('Marcar completado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: AppColors.white,
                      textStyle: AppTypography.etiquetaSm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.mdLg),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 34,
                height: 34,
                child: Tooltip(
                  message: 'Reprogramar',
                  child: OutlinedButton(
                    onPressed: () => _reschedule(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.forestGreen,
                      side: const BorderSide(color: AppColors.forestGreen),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.mdLg),
                      ),
                    ),
                    child: const Icon(Icons.event_repeat_rounded, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip() {
    if (step.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd, vertical: AppSpacing.xxsPlus),
        decoration: BoxDecoration(
          color: AppColors.statusHealthyBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          'Completado',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.forestGreen,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      );
    }
    if (step.isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd, vertical: AppSpacing.xxsPlus),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          'Vencido',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      );
    }
    if (step.isScheduled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd, vertical: AppSpacing.xxsPlus),
        decoration: BoxDecoration(
          color: AppColors.warmAmber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          'Próximo',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.burntOrange,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd, vertical: AppSpacing.xxsPlus),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        'En espera',
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

  Future<void> _reschedule(BuildContext context) async {
    final bloc = context.read<TreatmentBloc>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Si el paso esta vencido, su fecha original queda antes de "hoy" y
    // showDatePicker exige initialDate >= firstDate: se ajusta a hoy.
    final initialDate =
        step.scheduledDate.isBefore(today) ? today : step.scheduledDate;

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
        treatmentId: treatmentId,
        stepId: step.id,
        newDate: picked,
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
        padding: const EdgeInsets.all(AppSpacing.giant),
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
            const SizedBox(height: AppSpacing.huge),
            Text(
              'Sin tratamientos activos',
              style: AppTypography.tituloMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
        padding: const EdgeInsets.all(AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.offlineGrey),
            const SizedBox(height: AppSpacing.xxlPlus),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
