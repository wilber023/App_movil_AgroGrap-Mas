import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/treatment_entity.dart';
import '../bloc/treatment_bloc.dart';
import '../widgets/agenda_filter_chips_row.dart';
import '../widgets/agenda_section_header.dart';
import '../widgets/agenda_state_views.dart';
import '../widgets/agenda_summary_header.dart';
import '../widgets/treatment_agenda_helpers.dart';
import '../widgets/treatment_card.dart';

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
            return AgendaErrorView(
              message: state.message,
              onRetry: () => context
                  .read<TreatmentBloc>()
                  .add(const TreatmentAgendaRequested()),
            );
          }
          if (state is TreatmentAgendaLoaded) {
            if (state.treatments.isEmpty) return const AgendaEmptyView();
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

class _AgendaListView extends StatefulWidget {
  final List<TreatmentEntity> treatments;
  const _AgendaListView({required this.treatments});

  @override
  State<_AgendaListView> createState() => _AgendaListViewState();
}

class _AgendaListViewState extends State<_AgendaListView> {
  // "Todos" por defecto: conserva el comportamiento actual sin filtrar nada.
  AgendaFilter _filter = AgendaFilter.todos;

  List<TreatmentEntity> get _filteredTreatments {
    switch (_filter) {
      case AgendaFilter.todos:
        return widget.treatments;
      case AgendaFilter.hoy:
        return widget.treatments.where((t) => t.isDueToday).toList();
      case AgendaFilter.semana:
        return widget.treatments.where((t) => t.isDueThisWeek).toList();
      case AgendaFilter.vencidos:
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
          AgendaSummaryHeader(treatments: widget.treatments),
          const SizedBox(height: AppSpacing.xxxl),
          AgendaFilterChipsRow(
            selected: _filter,
            treatments: widget.treatments,
            onSelected: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          if (filtered.isEmpty)
            const AgendaFilteredEmptyState()
          else if (_filter == AgendaFilter.todos)
            ..._buildGroupedSections(filtered)
          else
            ...filtered.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxlPlus),
                  child: TreatmentCard(treatment: t),
                )),
        ],
      ),
    );
  }

  /// Agrupa por seccion preservando el orden ya calculado en [treatments]
  /// dentro de cada grupo. Solo se usa cuando el filtro activo es "Todos":
  /// los demas filtros ya representan una unica categoria.
  List<Widget> _buildGroupedSections(List<TreatmentEntity> treatments) {
    final groups = <AgendaSection, List<TreatmentEntity>>{};
    for (final t in treatments) {
      groups.putIfAbsent(sectionFor(t), () => []).add(t);
    }

    final widgets = <Widget>[];
    for (final section in agendaSectionOrder) {
      final items = groups[section];
      if (items == null || items.isEmpty) continue;

      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl, top: AppSpacing.xs),
        child: AgendaSectionHeader(section: section, count: items.length),
      ));
      widgets.addAll(items.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxlPlus),
            child: TreatmentCard(treatment: t),
          )));
      widgets.add(const SizedBox(height: AppSpacing.lg));
    }
    return widgets;
  }
}
