import 'package:equatable/equatable.dart';

import 'aprendiz_activity_summary_entity.dart';
import 'aprendiz_progress_entity.dart';
import 'aprendiz_recommendation_entity.dart';
import 'weekly_goal_entity.dart';

/// Agregado que la pantalla de Perfil necesita para renderizarse completa.
class AprendizProfileOverviewEntity extends Equatable {
  final String userName;
  final String userInitials;
  final String? email;
  final AprendizProgressEntity progress;
  final AprendizActivitySummaryEntity activitySummary;
  final List<WeeklyGoalEntity> weeklyGoals;
  final AprendizRecommendationEntity recommendation;
  final bool offlineModeEnabled;

  const AprendizProfileOverviewEntity({
    required this.userName,
    required this.userInitials,
    required this.email,
    required this.progress,
    required this.activitySummary,
    required this.weeklyGoals,
    required this.recommendation,
    required this.offlineModeEnabled,
  });

  @override
  List<Object?> get props => [
        userName,
        userInitials,
        email,
        progress,
        activitySummary,
        weeklyGoals,
        recommendation,
        offlineModeEnabled,
      ];
}
