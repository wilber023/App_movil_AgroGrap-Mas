import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import 'home_section_skeleton.dart';

/// Skeleton de carga de [AprendizHomePage].
class HomeLoadingView extends StatelessWidget {
  const HomeLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxlPlus,
        AppSpacing.xhuge,
        AppSpacing.xxlPlus,
        AppSpacing.colossal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          HomeSectionSkeleton(height: 92),
          SizedBox(height: AppSpacing.xxlPlus),
          HomeSectionSkeleton(height: 140),
          SizedBox(height: AppSpacing.xxlPlus),
          HomeSectionSkeleton(height: 96),
          SizedBox(height: AppSpacing.xxlPlus),
          HomeSectionSkeleton(height: 200),
          SizedBox(height: AppSpacing.xxlPlus),
          HomeSectionSkeleton(height: 100),
          SizedBox(height: AppSpacing.xxlPlus),
          HomeSectionSkeleton(height: 140),
          SizedBox(height: AppSpacing.xxlPlus),
          HomeSectionSkeleton(height: 160),
        ],
      ),
    );
  }
}
