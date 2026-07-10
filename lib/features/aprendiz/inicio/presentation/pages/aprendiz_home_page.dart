import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../cultivo/cultivo.dart';
import '../../../cultivo/domain/entities/crop_activity_entity.dart';
import '../../../diagnostico/diagnostico.dart';
import '../../../agenda/agenda.dart';
import '../bloc/aprendiz_home_bloc.dart';
import '../widgets/home_crop_catalog_section.dart';
import '../widgets/home_crop_stage_card.dart';
import '../widgets/home_crop_status_card.dart';
import '../widgets/home_daily_summary_section.dart';
import '../widgets/home_fun_fact_card.dart';
import '../widgets/home_header.dart';
import '../widgets/home_notices_card.dart';
import '../widgets/home_phytosanitary_alert_card.dart';
import '../widgets/home_recent_activity_list.dart';
import '../widgets/home_recommendation_card.dart';
import '../widgets/home_scan_cta_card.dart';
import '../widgets/home_section_skeleton.dart';
import '../widgets/home_today_tasks_section.dart';
import '../../domain/entities/crop_catalog_item_entity.dart';
import '../../domain/entities/home_recommendation_entity.dart';

class AprendizHomePage extends StatelessWidget {
  const AprendizHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AprendizHomeBloc>()..add(const HomeOverviewRequested()),
      child: const _AprendizHomeView(),
    );
  }
}

class _AprendizHomeView extends StatelessWidget {
  const _AprendizHomeView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AprendizHomeBloc, AprendizHomeState>(
      listenWhen: (previous, current) =>
          current is HomeLoaded && current.dueInspection != null && !current.modalAlreadyShown,
      listener: (context, state) {
        if (state is HomeLoaded && state.dueInspection != null && !state.modalAlreadyShown) {
          context.read<AprendizHomeBloc>().add(const DueInspectionModalShown());
          _showInspectionModal(context, state.dueInspection!);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.aMint,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<AprendizHomeBloc, AprendizHomeState>(
            builder: (context, state) {
              final userName = state is HomeLoaded ? state.overview.userName : '';
              final hasNotices = state is HomeLoaded && state.overview.notices.isNotEmpty;

              return Column(
                children: [
                  HomeHeader(userName: userName, hasNotices: hasNotices),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (state is HomeFailure) {
                          return _HomeErrorView(
                            message: state.message,
                            onRetry: () =>
                                context.read<AprendizHomeBloc>().add(const HomeOverviewRequested()),
                          );
                        }
                        if (state is HomeLoaded) {
                          return RefreshIndicator(
                            color: AppColors.aSecondary,
                            onRefresh: () async =>
                                context.read<AprendizHomeBloc>().add(const HomeOverviewRequested()),
                            child: _HomeContent(state: state),
                          );
                        }
                        return const _HomeLoadingView();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showInspectionModal(BuildContext context, CropActivityEntity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _InspectionBottomSheet(
        activity: activity,
        onPostpone: () => context.read<AprendizHomeBloc>().add(InspectionPostponed(activity.id)),
      ),
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          HomeSectionSkeleton(height: 92),
          SizedBox(height: 16),
          HomeSectionSkeleton(height: 140),
          SizedBox(height: 16),
          HomeSectionSkeleton(height: 96),
          SizedBox(height: 16),
          HomeSectionSkeleton(height: 200),
          SizedBox(height: 16),
          HomeSectionSkeleton(height: 100),
          SizedBox(height: 16),
          HomeSectionSkeleton(height: 140),
          SizedBox(height: 16),
          HomeSectionSkeleton(height: 160),
        ],
      ),
    );
  }
}

class _HomeErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HomeErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.aOutline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.aOnSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final HomeLoaded state;

  const _HomeContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final overview = state.overview;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeNoticesCard(notices: overview.notices),
          if (overview.notices.isNotEmpty) const SizedBox(height: 16),

          HomeCropCatalogSection(
            catalog: overview.cropCatalog,
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AprendizCropRoutePage()),
            ),
            onSelectCrop: (crop) => _onSelectCrop(context, crop),
          ),
          const SizedBox(height: 18),

          HomeScanCtaCard(
            onScan: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiagnosisEntryAprendizPage()),
            ),
          ),
          const SizedBox(height: 18),

          HomeDailySummarySection(
            pendingTasksCount: overview.pendingTasksCount,
            cropStatus: overview.cropStatus,
          ),
          const SizedBox(height: 18),

          HomeCropStatusCard(
            status: overview.cropStatus,
            onRegisterCrop: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AprendizCropRegisterPage()),
            ),
          ),
          HomeCropStageCard(
            status: overview.cropStatus,
            onViewDetails: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AprendizCropRoutePage()),
            ),
          ),
          if (overview.cropStatus.hasCropPlan) const SizedBox(height: 16),
          HomeRecommendationCard(
            recommendation: overview.recommendation,
            onAction: overview.recommendation.action == HomeRecommendationAction.none
                ? null
                : () => _onRecommendationAction(context, overview.recommendation.action),
          ),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: HomePhytosanitaryAlertCard(alert: overview.phytosanitaryAlert)),
              if (overview.funFact != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: HomeFunFactCard(
                    funFact: overview.funFact,
                    onViewMore: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DiagnosisEntryAprendizPage()),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),

          HomeTodayTasksSection(
            tasks: overview.upcomingTasks,
            onViewCalendar: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AprendizAgendaPage()),
            ),
          ),
          const SizedBox(height: 24),

          HomeRecentActivityList(items: overview.recentActivity),
        ],
      ),
    );
  }

  void _onSelectCrop(BuildContext context, CropCatalogItemEntity crop) {
    if (crop.isActive) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AprendizCropRoutePage()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AprendizCropRegisterPage()));
    }
  }

  void _onRecommendationAction(BuildContext context, HomeRecommendationAction action) {
    switch (action) {
      case HomeRecommendationAction.registerCrop:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AprendizCropRegisterPage()));
        break;
      case HomeRecommendationAction.diagnosis:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosisEntryAprendizPage()));
        break;
      case HomeRecommendationAction.none:
        break;
    }
  }
}

// Bottom sheet de inspeccion pendiente (funcionalidad conservada tal cual).
class _InspectionBottomSheet extends StatelessWidget {
  final CropActivityEntity activity;
  final VoidCallback onPostpone;

  const _InspectionBottomSheet({required this.activity, required this.onPostpone});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.aOutlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(color: AppColors.aPrimaryFixed, shape: BoxShape.circle),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.aSurfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.aPrimaryFixed),
                        boxShadow: [
                          BoxShadow(color: AppColors.aPrimaryFixed.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.eco, color: AppColors.aPrimaryContainer, size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.aSecondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.aOnSecondaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        'Semana ${activity.weekNumber} · Inspección programada',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.aOnSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.05,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Es momento de inspeccionar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Toma una foto de tus plantas para que el modelo de IA analice su estado actual.',
                  style: TextStyle(fontSize: 15, color: AppColors.aOnSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiagnosisCameraAprendizPage(
                            weekNumber: activity.weekNumber,
                            activityId: activity.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, color: AppColors.aOnPrimary, size: 18),
                    label: const Text(
                      'IR A DIAGNÓSTICO',
                      style: TextStyle(
                        color: AppColors.aOnPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.05,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.aOrangeAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onPostpone();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.aSecondary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'POSPONER PARA MAÑANA',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.aSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.05,
                      ),
                    ),
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
