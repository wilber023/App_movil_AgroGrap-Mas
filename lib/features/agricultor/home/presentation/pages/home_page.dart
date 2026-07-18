import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../widgets/home_active_crops_section.dart';
import '../widgets/home_camera_action_card.dart';
import '../widgets/home_epidemiological_alert_section.dart';
import '../widgets/home_header.dart';
import '../widgets/home_premium_banner.dart';
import '../widgets/home_today_summary.dart';
import '../widgets/home_today_tasks_section.dart';

class HomePage extends StatelessWidget {
  /// Cambia de tab dentro del BottomNavigationBar (lo provee MainShell en
  /// main.dart). Si es null (ej. un test que monta HomePage aislada), los
  /// enlaces "Ver agenda"/"Ver todos" simplemente no hacen nada — no
  /// truena la pantalla.
  final ValueChanged<int>? onNavigateToTab;
  const HomePage({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxlPlus,
                  vertical: AppSpacing.xhuge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const HomePremiumBanner(),
                    const SizedBox(height: AppSpacing.huge),
                    const HomeCameraActionCard(),
                    const SizedBox(height: AppSpacing.xhuge),
                    HomeTodaySummary(onNavigateToTab: onNavigateToTab),
                    const SizedBox(height: AppSpacing.xhuge),
                    HomeActiveCropsSection(onNavigateToTab: onNavigateToTab),
                    const SizedBox(height: AppSpacing.xhuge),
                    const HomeEpidemiologicalAlertSection(),
                    const SizedBox(height: AppSpacing.xhuge),
                    HomeTodayTasksSection(onNavigateToTab: onNavigateToTab),
                    const SizedBox(height: AppSpacing.xhuge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
