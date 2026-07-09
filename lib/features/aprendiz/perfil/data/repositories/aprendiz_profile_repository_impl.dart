import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/network/network_info.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../agricultor/diagnosis/domain/entities/diagnosis_entity.dart';
import '../../../../login/auth/domain/entities/user_entity.dart';
import '../../../../login/auth/domain/usecases/get_current_user_usecase.dart';
import '../../../cultivo/domain/entities/crop_activity_entity.dart';
import '../../../cultivo/domain/entities/crop_plan_entity.dart';
import '../../../cultivo/domain/usecases/get_saved_crop_plan_usecase.dart';
import '../../../diagnostico/domain/usecases/get_diagnosis_history_aprendiz_usecase.dart';
import '../../domain/entities/aprendiz_activity_summary_entity.dart';
import '../../domain/entities/aprendiz_profile_overview_entity.dart';
import '../../domain/entities/aprendiz_progress_entity.dart';
import '../../domain/entities/aprendiz_recommendation_entity.dart';
import '../../domain/entities/weekly_goal_entity.dart';
import '../../domain/repositories/aprendiz_profile_repository.dart';
import '../datasources/aprendiz_profile_local_datasource.dart';
import '../datasources/aprendiz_profile_remote_datasource.dart';

/// Compone el Perfil del Aprendiz a partir de datos reales ya disponibles en
/// otros modulos (Auth, Cultivo, Diagnostico) — sin backend propio todavia
/// para progreso/gamificacion, ver [AprendizProfileRemoteDataSource]. El
/// nivel/XP/racha/objetivos/recomendacion se derivan con reglas simples y
/// documentadas sobre esos datos reales, nunca con valores aleatorios.
class AprendizProfileRepositoryImpl implements AprendizProfileRepository {
  final AprendizProfileRemoteDataSource remoteDataSource;
  final AprendizProfileLocalDataSource localDataSource;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final GetSavedCropPlanUseCase getSavedCropPlanUseCase;
  final GetDiagnosisHistoryAprendizUseCase getDiagnosisHistoryUseCase;
  final NetworkInfo networkInfo;

  AprendizProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.getCurrentUserUseCase,
    required this.getSavedCropPlanUseCase,
    required this.getDiagnosisHistoryUseCase,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AprendizProfileOverviewEntity>> getProfileOverview() async {
    final userResult = await getCurrentUserUseCase(const NoParams());
    final user = userResult.fold((_) => UserEntity.empty, (u) => u);

    final planResult = await getSavedCropPlanUseCase(const NoParams());
    final plan = planResult.fold((_) => null, (p) => p);

    final diagnosesResult = await getDiagnosisHistoryUseCase(const NoParams());
    final diagnoses = diagnosesResult.fold((_) => const <DiagnosisEntity>[], (d) => d);

    final activitySummary = _buildActivitySummary(user: user, plan: plan, diagnoses: diagnoses);
    final weeklyGoals = _buildWeeklyGoals(plan: plan, diagnoses: diagnoses);
    final recommendation = _buildRecommendation(plan: plan, diagnoses: diagnoses, weeklyGoals: weeklyGoals);
    final offlineModeEnabled = await localDataSource.getOfflineModeEnabled();

    final progress = await _resolveProgress(activitySummary: activitySummary, diagnoses: diagnoses);

    return Right(AprendizProfileOverviewEntity(
      userName: user.fullName.isNotEmpty ? user.fullName : user.username,
      userInitials: _initialsOf(user.fullName.isNotEmpty ? user.fullName : user.username),
      email: user.email,
      progress: progress,
      activitySummary: activitySummary,
      weeklyGoals: weeklyGoals,
      recommendation: recommendation,
      offlineModeEnabled: offlineModeEnabled,
    ));
  }

  @override
  Future<Either<Failure, bool>> getOfflineModeEnabled() async {
    return Right(await localDataSource.getOfflineModeEnabled());
  }

  @override
  Future<Either<Failure, Unit>> setOfflineModeEnabled(bool enabled) async {
    await localDataSource.setOfflineModeEnabled(enabled);
    return const Right(unit);
  }

  Future<AprendizProgressEntity> _resolveProgress({
    required AprendizActivitySummaryEntity activitySummary,
    required List<DiagnosisEntity> diagnoses,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        return await remoteDataSource.getProgress();
      } catch (_) {
        // Backend aun no expone el endpoint: se cae al calculo local.
      }
    }
    return _computeLocalProgress(activitySummary: activitySummary, diagnoses: diagnoses);
  }

  /// XP = 20 por diagnostico + 15 por actividad completada + 50 si hay un
  /// cultivo registrado. Cada 100 XP se sube un nivel. La racha cuenta dias
  /// consecutivos (desde hoy hacia atras) con al menos un diagnostico.
  AprendizProgressEntity _computeLocalProgress({
    required AprendizActivitySummaryEntity activitySummary,
    required List<DiagnosisEntity> diagnoses,
  }) {
    const xpPerDiagnosis = 20;
    const xpPerActivity = 15;
    const xpForCropPlan = 50;
    const xpPerLevel = 100;

    final xp = activitySummary.diagnosesCompleted * xpPerDiagnosis +
        activitySummary.activitiesCompleted * xpPerActivity +
        (activitySummary.cropsRegistered > 0 ? xpForCropPlan : 0);

    final level = 1 + xp ~/ xpPerLevel;

    return AprendizProgressEntity(
      level: level,
      xp: xp,
      xpForNextLevel: xpPerLevel,
      streakDays: _computeStreakDays(diagnoses),
    );
  }

  int _computeStreakDays(List<DiagnosisEntity> diagnoses) {
    if (diagnoses.isEmpty) return 0;

    final days = diagnoses.map((d) => _dateOnly(d.diagnosedAt)).toSet();
    var streak = 0;
    var cursor = _dateOnly(DateTime.now());

    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  AprendizActivitySummaryEntity _buildActivitySummary({
    required UserEntity user,
    required CropPlanEntity? plan,
    required List<DiagnosisEntity> diagnoses,
  }) {
    final activitiesCompleted = plan?.activities.where((a) => a.status == ActivityStatus.completed).length ?? 0;
    final learningStart = user.createdAt ?? plan?.startDate;
    final daysLearning = learningStart == null
        ? 0
        : DateTime.now().difference(learningStart).inDays.clamp(0, 1 << 30);

    return AprendizActivitySummaryEntity(
      cropsRegistered: plan != null ? 1 : 0,
      diagnosesCompleted: diagnoses.length,
      activitiesCompleted: activitiesCompleted,
      daysLearning: daysLearning,
    );
  }

  List<WeeklyGoalEntity> _buildWeeklyGoals({
    required CropPlanEntity? plan,
    required List<DiagnosisEntity> diagnoses,
  }) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    final diagnosesThisWeek = diagnoses.where((d) => d.diagnosedAt.isAfter(weekAgo)).length;

    // CropActivityEntity no registra fecha de finalizacion: se aproxima con
    // actividades completadas cuya fecha programada cae en la ultima semana.
    final activitiesThisWeek = plan?.activities
            .where((a) => a.status == ActivityStatus.completed && a.scheduledDate.isAfter(weekAgo))
            .length ??
        0;

    return [
      WeeklyGoalEntity(
        type: WeeklyGoalType.registerCrop,
        label: 'Registrar un cultivo',
        current: plan != null ? 1 : 0,
        target: 1,
      ),
      WeeklyGoalEntity(
        type: WeeklyGoalType.doDiagnosis,
        label: 'Realizar un diagnóstico',
        current: diagnosesThisWeek.clamp(0, 1),
        target: 1,
      ),
      WeeklyGoalEntity(
        type: WeeklyGoalType.completeAgendaActivities,
        label: 'Completar actividades de la agenda',
        current: activitiesThisWeek.clamp(0, 3),
        target: 3,
      ),
    ];
  }

  AprendizRecommendationEntity _buildRecommendation({
    required CropPlanEntity? plan,
    required List<DiagnosisEntity> diagnoses,
    required List<WeeklyGoalEntity> weeklyGoals,
  }) {
    if (plan == null) {
      return const AprendizRecommendationEntity(
        title: 'Registra tu primer cultivo',
        description: 'Aún no tienes un cultivo activo. Regístralo para generar tu plan de actividades.',
        actionLabel: 'Registrar cultivo',
        action: RecommendationAction.registerCrop,
      );
    }

    if (diagnoses.isEmpty) {
      return const AprendizRecommendationEntity(
        title: 'Haz tu primer diagnóstico',
        description: 'Te recomendamos realizar un diagnóstico para aprender a identificar enfermedades comunes.',
        actionLabel: 'Ir a Diagnóstico',
        action: RecommendationAction.diagnosis,
      );
    }

    final agendaGoal = weeklyGoals.firstWhere((g) => g.type == WeeklyGoalType.completeAgendaActivities);
    if (!agendaGoal.isCompleted) {
      return const AprendizRecommendationEntity(
        title: 'Revisa tu agenda',
        description: 'Tienes actividades pendientes esta semana. Complétalas para mantener tu racha de aprendizaje.',
        actionLabel: 'Ir a Agenda',
        action: RecommendationAction.agenda,
      );
    }

    return const AprendizRecommendationEntity(
      title: '¡Vas muy bien!',
      description: 'Sigue así: revisa tu cultivo con frecuencia para detectar problemas a tiempo.',
      actionLabel: 'Ver mi cultivo',
      action: RecommendationAction.none,
    );
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
