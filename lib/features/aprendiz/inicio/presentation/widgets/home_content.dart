import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../cultivo/cultivo.dart';
import '../../../diagnostico/diagnostico.dart';
import '../../../agenda/agenda.dart';
import '../bloc/aprendiz_home_bloc.dart';
import '../../domain/entities/crop_catalog_item_entity.dart';
import '../../domain/entities/home_recommendation_entity.dart';
import '../../domain/entities/phytosanitary_alert_entity.dart';
import 'home_crop_catalog_section.dart';
import 'home_crop_stage_card.dart';
import 'home_crop_status_card.dart';
import 'home_daily_summary_section.dart';
import 'home_notices_card.dart';
import 'home_phytosanitary_alert_card.dart';
import 'home_recent_activity_list.dart';
import 'home_recommendation_card.dart';
import 'home_scan_cta_card.dart';
import 'home_today_tasks_section.dart';

/// Contenido principal de [AprendizHomePage] una vez cargado.
class HomeContent extends StatelessWidget {
  final HomeLoaded state;

  const HomeContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final overview = state.overview;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxlPlus,
        AppSpacing.xxlPlus,
        AppSpacing.xxlPlus,
        AppSpacing.colossal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeNoticesCard(notices: overview.notices),
          if (overview.notices.isNotEmpty) const SizedBox(height: AppSpacing.xxlPlus),

          HomeCropCatalogSection(
            catalog: overview.cropCatalog,
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AprendizCropRoutePage()),
            ),
            onSelectCrop: (crop) => _onSelectCrop(context, crop),
          ),
          const SizedBox(height: AppSpacing.xxxl),

          HomeScanCtaCard(
            onScan: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiagnosisEntryAprendizPage()),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),

          HomeDailySummarySection(
            pendingTasksCount: overview.pendingTasksCount,
            cropStatus: overview.cropStatus,
          ),
          const SizedBox(height: AppSpacing.xxxl),

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
          if (overview.cropStatus.hasCropPlan) const SizedBox(height: AppSpacing.xxlPlus),
          HomeRecommendationCard(
            recommendation: overview.recommendation,
            onAction: overview.recommendation.action == HomeRecommendationAction.none
                ? null
                : () => _onRecommendationAction(context, overview.recommendation.action),
          ),
          const SizedBox(height: AppSpacing.xxxl),

          if (overview.phytosanitaryAlert.level != PhytosanitaryAlertLevel.none) ...[
            HomePhytosanitaryAlertCard(alert: overview.phytosanitaryAlert),
            const SizedBox(height: AppSpacing.xxxl),
          ],

          HomeTodayTasksSection(
            tasks: overview.upcomingTasks,
            onViewCalendar: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AprendizAgendaPage()),
            ),
          ),
          const SizedBox(height: AppSpacing.xhuge),

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
