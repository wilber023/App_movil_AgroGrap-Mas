import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/agenda_activity_entity.dart';
import '../bloc/agenda_bloc.dart';
import '../widgets/agenda_app_bar.dart';
import '../widgets/agenda_crop_summary_row.dart';
import '../widgets/agenda_month_calendar.dart';
import '../widgets/agenda_today_stage_card.dart';
import '../widgets/agenda_upcoming_section.dart';

class AprendizAgendaPage extends StatelessWidget {
  const AprendizAgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AgendaBloc>()..add(const AgendaOverviewRequested()),
      child: const _AgendaView(),
    );
  }
}

class _AgendaView extends StatelessWidget {
  const _AgendaView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AgendaBloc, AgendaState>(
      listenWhen: (previous, current) =>
          current is AgendaLoaded && current.actionError != null,
      listener: (context, state) {
        final message = (state as AgendaLoaded).actionError;
        if (message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.aMint,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AgendaAppBar(),
              Expanded(
                child: BlocBuilder<AgendaBloc, AgendaState>(
                  builder: (context, state) {
                    if (state is AgendaFailure) {
                      return _ErrorContent(
                        message: state.message,
                        onRetry: () => context
                            .read<AgendaBloc>()
                            .add(const AgendaOverviewRequested()),
                      );
                    }
                    if (state is! AgendaLoaded) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.aSecondary),
                      );
                    }
                    return _AgendaContent(state: state);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaContent extends StatelessWidget {
  final AgendaLoaded state;
  const _AgendaContent({required this.state});

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final activities = state.overview.activities;
    final selectedDayActivity = activities
        .where((a) => _isSameDay(a.scheduledDate, state.selectedDay))
        .fold<AgendaActivityEntity?>(null, (acc, a) => acc ?? a);

    final upcoming = activities
        .where((a) =>
            a.status == AgendaActivityStatus.pending &&
            a.scheduledDate.isAfter(DateTime(
              state.selectedDay.year,
              state.selectedDay.month,
              state.selectedDay.day,
            )))
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgendaMonthCalendar(
            selectedDay: state.selectedDay,
            visibleMonth: state.visibleMonth,
            activities: activities,
            onDaySelected: (day) =>
                context.read<AgendaBloc>().add(AgendaDaySelected(day)),
            onPreviousMonth: () =>
                context.read<AgendaBloc>().add(const AgendaMonthChanged(-1)),
            onNextMonth: () =>
                context.read<AgendaBloc>().add(const AgendaMonthChanged(1)),
          ),
          AgendaCropSummaryRow(cropContext: state.overview.cropContext),
          AgendaTodayStageCard(
            activity: selectedDayActivity,
            selectedDay: state.selectedDay,
            isProcessingAction: state.isProcessingAction,
            onMarkCompleted: selectedDayActivity == null
                ? () {}
                : () => context
                    .read<AgendaBloc>()
                    .add(AgendaActivityCompleted(selectedDayActivity.id)),
          ),
          AgendaUpcomingSection(
            upcomingActivities: upcoming.take(5).toList(),
            onTaskSelected: (day) =>
                context.read<AgendaBloc>().add(AgendaDaySelected(day)),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorContent({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
