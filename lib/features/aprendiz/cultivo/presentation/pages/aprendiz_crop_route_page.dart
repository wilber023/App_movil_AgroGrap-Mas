import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../agenda/agenda.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../../domain/entities/crop_plan_entity.dart';
import '../bloc/cultivo_bloc.dart';
import '../widgets/cultivo_app_bar.dart';
import '../widgets/cultivo_greeting_header.dart';
import '../widgets/cultivo_next_task_row.dart';
import '../widgets/cultivo_register_cta.dart';
import '../widgets/cultivo_summary_card.dart';
import '../widgets/cultivo_today_stage_card.dart';
import 'aprendiz_crop_register_page.dart';

/// Total de semanas del ciclo de cultivo, usado para mostrar "Semana N de
/// 18" (mismo criterio ya establecido en el resto de la feature Aprendiz).
const int _kTotalCropWeeks = 18;

class AprendizCropRoutePage extends StatelessWidget {
  const AprendizCropRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CultivoBloc>()..add(const CultivoOverviewRequested()),
      child: const _CultivoView(),
    );
  }
}

class _CultivoView extends StatelessWidget {
  const _CultivoView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aMint,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const CultivoAppBar(),
            Expanded(
              child: BlocBuilder<CultivoBloc, CultivoState>(
                builder: (context, state) {
                  if (state is CultivoFailure) {
                    return _ErrorContent(
                      message: state.message,
                      onRetry: () => context
                          .read<CultivoBloc>()
                          .add(const CultivoOverviewRequested()),
                    );
                  }
                  if (state is! CultivoLoaded) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.aSecondary),
                    );
                  }
                  return _CultivoContent(plan: state.plan);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CultivoContent extends StatelessWidget {
  final CropPlanEntity plan;
  const _CultivoContent({required this.plan});

  CropActivityEntity? get _todayActivity {
    try {
      return plan.activities.firstWhere(
        (a) => a.status == ActivityStatus.pending && a.weekNumber == plan.currentWeek,
      );
    } catch (_) {
      return null;
    }
  }

  CropActivityEntity? get _nextTask {
    final upcoming = plan.activities
        .where((a) => a.status == ActivityStatus.pending && a.weekNumber > plan.currentWeek)
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  void _openAgenda(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AprendizAgendaPage()));
  }

  @override
  Widget build(BuildContext context) {
    final todayActivity = _todayActivity;
    final nextTask = _nextTask;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CultivoGreetingHeader(),
          CultivoSummaryCard(
            cropName: plan.cropName,
            currentWeek: plan.currentWeek,
            totalWeeks: _kTotalCropWeeks,
          ),
          CultivoTodayStageCard(
            currentWeek: plan.currentWeek,
            stageName: plan.currentStage,
            stageDescription: todayActivity?.description ??
                'Continúa con el cuidado habitual de tu cultivo esta semana.',
            onViewTodayTask: () => _openAgenda(context),
          ),
          if (nextTask != null)
            CultivoNextTaskRow(
              taskTitle: nextTask.title,
              scheduledDate: nextTask.scheduledDate,
              onTap: () => _openAgenda(context),
            ),
          CultivoRegisterCta(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AprendizCropRegisterPage()),
            ),
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
