import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../agricultor/diagnosis/domain/entities/diagnosis_entity.dart';
import '../../../../login/auth/domain/entities/user_entity.dart';
import '../../../../login/auth/domain/usecases/get_current_user_usecase.dart';
import '../../../../notifications/domain/usecases/get_notification_history_usecase.dart';
import '../../../agenda/domain/entities/agenda_activity_entity.dart';
import '../../../agenda/domain/entities/agenda_overview_entity.dart';
import '../../../agenda/domain/usecases/get_agenda_overview_usecase.dart';
import '../../../cultivo/domain/entities/crop_activity_entity.dart';
import '../../../cultivo/domain/entities/crop_health_entity.dart';
import '../../../cultivo/domain/entities/crop_plan_entity.dart';
import '../../../cultivo/domain/usecases/get_crop_health_indicator_usecase.dart';
import '../../../cultivo/domain/usecases/get_due_inspection_activity_usecase.dart' show resolveDueInspectionActivity;
import '../../../cultivo/domain/usecases/get_saved_crop_plan_usecase.dart';
import '../../../diagnostico/domain/usecases/get_diagnosis_history_aprendiz_usecase.dart';
import '../../domain/entities/aprendiz_home_overview_entity.dart';
import '../../domain/entities/crop_catalog_item_entity.dart';
import '../../domain/entities/crop_status_summary_entity.dart';
import '../../domain/entities/home_notice_entity.dart';
import '../../domain/entities/home_recommendation_entity.dart';
import '../../domain/entities/phytosanitary_alert_entity.dart';
import '../../domain/entities/recent_activity_item_entity.dart';
import '../../domain/repositories/aprendiz_home_repository.dart';

/// Compone el resumen de Inicio a partir de casos de uso ya existentes de
/// Auth, Cultivo, Diagnostico, Agenda y Notificaciones — no persiste ni
/// duplica datos, solo los agrega. Ver [AprendizHomeOverviewEntity] para el
/// detalle de cada seccion.
class AprendizHomeRepositoryImpl implements AprendizHomeRepository {
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final GetSavedCropPlanUseCase getSavedCropPlanUseCase;
  final GetCropHealthIndicatorUseCase getCropHealthIndicatorUseCase;
  final GetDiagnosisHistoryAprendizUseCase getDiagnosisHistoryUseCase;
  final GetAgendaOverviewUseCase getAgendaOverviewUseCase;
  final GetNotificationHistoryUseCase getNotificationHistoryUseCase;

  AprendizHomeRepositoryImpl({
    required this.getCurrentUserUseCase,
    required this.getSavedCropPlanUseCase,
    required this.getCropHealthIndicatorUseCase,
    required this.getDiagnosisHistoryUseCase,
    required this.getAgendaOverviewUseCase,
    required this.getNotificationHistoryUseCase,
  });

  /// Catalogo real de cultivos que el Aprendiz puede sembrar — el mismo que
  /// ofrece el formulario de Registrar Cultivo
  /// (`aprendiz_crop_register_page.dart`), para que "Mis cultivos" muestre
  /// exactamente las opciones que existen en la app.
  static const List<(String emoji, String name)> _catalog = [
    ('🍈', 'Calabaza'),
    ('🫘', 'Frijol'),
    ('🌽', 'Maíz'),
    ('🥔', 'Papa'),
    ('🍅', 'Tomate'),
  ];

  static const Map<CropGrowthStage, List<String>> _stageKeywords = {
    CropGrowthStage.siembra: ['siembra', 'pendiente de inicio', 'germinacion', 'germinación'],
    CropGrowthStage.crecimiento: ['crecimiento', 'vegetativo', 'plántula', 'plantula'],
    CropGrowthStage.floracion: ['floracion', 'floración'],
    CropGrowthStage.fruto: ['fruto', 'fructificacion', 'fructificación', 'llenado'],
    CropGrowthStage.cosecha: ['cosecha', 'maduracion', 'maduración'],
  };

  @override
  Future<Either<Failure, AprendizHomeOverviewEntity>> getHomeOverview() async {
    // Las 6 fuentes de abajo son independientes entre si (ninguna consume el
    // resultado de otra), asi que se disparan todas de una vez y se esperan
    // en paralelo -- antes se esperaban una por una, lo que sumaba la
    // latencia de cada llamada (incluida red) en vez de tomar solo la mas
    // lenta. `dueInspection` ya no dispara su propia llamada de red: se
    // deriva del `plan` que este mismo metodo ya obtuvo (ver
    // `resolveDueInspectionActivity`), eliminando una segunda consulta
    // redundante del plan de cultivo.
    final userFuture = getCurrentUserUseCase(NoParams());
    final planFuture = getSavedCropPlanUseCase(NoParams());
    final healthFuture = getCropHealthIndicatorUseCase(const NoParams());
    final diagnosesFuture = getDiagnosisHistoryUseCase(NoParams());
    final agendaFuture = getAgendaOverviewUseCase(NoParams());
    final phytosanitaryAlertFuture = _resolvePhytosanitaryAlert();

    await Future.wait([
      userFuture,
      planFuture,
      healthFuture,
      diagnosesFuture,
      agendaFuture,
      phytosanitaryAlertFuture,
    ]);

    final user = (await userFuture).fold(
      (_) => UserEntity.empty,
      (u) => u,
    );
    final plan = (await planFuture).fold(
      (_) => null,
      (p) => p,
    );
    final dueInspection = plan == null ? null : resolveDueInspectionActivity(plan);
    final health = (await healthFuture).fold(
      (_) => null,
      (h) => h,
    );
    final diagnoses = (await diagnosesFuture).fold(
      (_) => const <DiagnosisEntity>[],
      (d) => d,
    );
    final agendaOverview = (await agendaFuture).fold(
      (_) => null,
      (o) => o,
    );
    final phytosanitaryAlert = await phytosanitaryAlertFuture;
    final latestDiagnosis = _latestDiagnosis(diagnoses);

    return Right(
      AprendizHomeOverviewEntity(
        userName: user.fullName.isNotEmpty ? user.fullName : user.username,
        notices: _buildNotices(plan: plan, dueInspection: dueInspection),
        phytosanitaryAlert: phytosanitaryAlert,
        nextActivity: _nextAgendaActivity(agendaOverview),
        cropStatus: _buildCropStatus(plan: plan, health: health, latestDiagnosis: latestDiagnosis),
        recommendation: _buildRecommendation(plan: plan, diagnoses: diagnoses),
        recentActivity: _buildRecentActivity(plan: plan, diagnoses: diagnoses),
        cropCatalog: _buildCropCatalog(plan),
        upcomingTasks: _upcomingTasks(agendaOverview),
        pendingTasksCount: _pendingTasksCount(agendaOverview),
        funFact: latestDiagnosis?.llmResponse?.aprendizaje.trim().isNotEmpty == true
            ? latestDiagnosis!.llmResponse!.aprendizaje.trim()
            : null,
        dueInspection: dueInspection,
      ),
    );
  }

  /// La alerta que antes venia del endpoint nacional de clustering quedaba
  /// desactualizada (no reflejaba lo que el usuario ya veia en la campanita
  /// de notificaciones). Ahora se reusa la misma fuente que
  /// `NotificationsPage`: el historial local de push recibidas
  /// (`NotificationHistoryRepository.getHistory()`, ya ordenado del mas
  /// reciente al mas antiguo), tomando solo la mas reciente. Sin
  /// notificaciones guardadas -> sin alerta, nunca datos inventados.
  ///
  /// El historial no trae nivel de severidad (solo `title`/`body`); se
  /// mapea a `moderate` como unico nivel "activo", igual que antes.
  Future<PhytosanitaryAlertEntity> _resolvePhytosanitaryAlert() async {
    final history = (await getNotificationHistoryUseCase(const NoParams())).fold(
      (_) => null,
      (items) => items,
    );
    if (history == null || history.isEmpty) return PhytosanitaryAlertEntity.none;

    final latest = history.first;
    final message = latest.body.trim().isNotEmpty ? latest.body.trim() : latest.title.trim();
    if (message.isEmpty) return PhytosanitaryAlertEntity.none;

    return PhytosanitaryAlertEntity(
      level: PhytosanitaryAlertLevel.moderate,
      message: message,
    );
  }

  List<HomeNoticeEntity> _buildNotices({
    required CropPlanEntity? plan,
    required CropActivityEntity? dueInspection,
  }) {
    final notices = <HomeNoticeEntity>[];
    if (plan == null) {
      notices.add(
        const HomeNoticeEntity(
          type: HomeNoticeType.noCropPlan,
          message: 'Aún no has registrado un cultivo.',
        ),
      );
    }
    if (dueInspection != null) {
      notices.add(
        HomeNoticeEntity(
          type: HomeNoticeType.dueInspection,
          message: 'Tienes una inspección pendiente hoy: ${dueInspection.title}.',
        ),
      );
    }
    return notices;
  }

  AgendaActivityEntity? _nextAgendaActivity(AgendaOverviewEntity? overview) {
    final pending = _pendingActivitiesSorted(overview);
    return pending.isEmpty ? null : pending.first;
  }

  List<AgendaActivityEntity> _pendingActivitiesSorted(AgendaOverviewEntity? overview) {
    if (overview == null) return const [];
    return overview.activities.where((a) => a.status == AgendaActivityStatus.pending).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  List<AgendaActivityEntity> _upcomingTasks(AgendaOverviewEntity? overview) {
    return _pendingActivitiesSorted(overview).take(3).toList();
  }

  int _pendingTasksCount(AgendaOverviewEntity? overview) {
    return _pendingActivitiesSorted(overview).length;
  }

  List<CropCatalogItemEntity> _buildCropCatalog(CropPlanEntity? plan) {
    final activeName = plan?.cropName.trim().toLowerCase();
    return _catalog
        .map((c) => CropCatalogItemEntity(
              emoji: c.$1,
              name: c.$2,
              isActive: activeName != null && c.$2.toLowerCase() == activeName,
            ))
        .toList();
  }

  CropStatusSummaryEntity _buildCropStatus({
    required CropPlanEntity? plan,
    required CropHealthEntity? health,
    required DiagnosisEntity? latestDiagnosis,
  }) {
    if (plan == null) return CropStatusSummaryEntity.empty;

    return CropStatusSummaryEntity(
      hasCropPlan: true,
      cropName: plan.cropName,
      lastUpdate: latestDiagnosis?.diagnosedAt,
      lastDiagnosisLabel: latestDiagnosis == null
          ? 'Sin novedades'
          : (latestDiagnosis.statusLabel == 'Saludable' ? 'Sin novedades' : latestDiagnosis.diseaseName),
      currentWeek: plan.currentWeek,
      progressPercentage: plan.progressPercentage,
      stageLabel: plan.currentStage,
      stageIndex: _stageIndexOf(plan.currentStage, plan.progressPercentage),
      healthStatus: health?.status,
    );
  }

  /// Ubica la etapa real reportada por el backend dentro de la secuencia
  /// generica de crecimiento (por coincidencia de palabras clave); si no
  /// hay coincidencia, se aproxima con el progreso del ciclo. Nunca inventa
  /// una etapa: solo posiciona la real dentro de esta escala visual.
  int _stageIndexOf(String stageLabel, double progressPercentage) {
    final normalized = stageLabel.toLowerCase();
    for (final entry in _stageKeywords.entries) {
      if (entry.value.any(normalized.contains)) return entry.key.index;
    }
    final clamped = progressPercentage.clamp(0, 100);
    return (clamped / 100 * (CropGrowthStage.values.length - 1)).round();
  }

  HomeRecommendationEntity _buildRecommendation({
    required CropPlanEntity? plan,
    required List<DiagnosisEntity> diagnoses,
  }) {
    if (plan == null) {
      return const HomeRecommendationEntity(
        message: 'Registra tu primer cultivo para comenzar tu plan de actividades.',
        action: HomeRecommendationAction.registerCrop,
      );
    }
    if (diagnoses.isEmpty) {
      return const HomeRecommendationEntity(
        message: 'Realiza un diagnóstico para conocer el estado actual de tu cultivo.',
        action: HomeRecommendationAction.diagnosis,
      );
    }
    return const HomeRecommendationEntity(
      message:
          'Revisa las hojas más jóvenes durante la inspección para detectar cambios a tiempo.',
      action: HomeRecommendationAction.none,
    );
  }

  List<RecentActivityItemEntity> _buildRecentActivity({
    required CropPlanEntity? plan,
    required List<DiagnosisEntity> diagnoses,
  }) {
    final items = <RecentActivityItemEntity>[];

    final latestDiagnosis = _latestDiagnosis(diagnoses);
    if (latestDiagnosis != null) {
      items.add(
        RecentActivityItemEntity(
          type: RecentActivityType.diagnosis,
          label: 'Diagnóstico realizado',
          detail: latestDiagnosis.diseaseName,
          date: latestDiagnosis.diagnosedAt,
        ),
      );
    }

    if (plan != null) {
      items.add(
        RecentActivityItemEntity(
          type: RecentActivityType.cropRegistered,
          label: 'Cultivo registrado',
          detail: plan.cropName,
          date: plan.startDate,
        ),
      );

      final lastCompleted = _lastCompletedActivity(plan.activities);
      if (lastCompleted != null) {
        items.add(
          RecentActivityItemEntity(
            type: RecentActivityType.activityCompleted,
            label: 'Actividad completada',
            detail: lastCompleted.title,
            date: lastCompleted.scheduledDate,
          ),
        );
      }
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items.take(3).toList();
  }

  // No usa Iterable.reduce: la lista concreta que llega aqui es
  // List<AprendizDiagnosisModel> (subtipo covariante de DiagnosisEntity), y
  // reduce() exige que el closure combine coincida exactamente con el tipo
  // reificado en tiempo de ejecucion de la lista — con una lambda tipada
  // como (DiagnosisEntity, DiagnosisEntity) eso lanza un TypeError en
  // runtime ("is not a subtype of ... of 'combine'"). Un bucle explicito
  // evita ese problema de covarianza de genericos.
  DiagnosisEntity? _latestDiagnosis(List<DiagnosisEntity> diagnoses) {
    DiagnosisEntity? latest;
    for (final diagnosis in diagnoses) {
      if (latest == null || diagnosis.diagnosedAt.isAfter(latest.diagnosedAt)) {
        latest = diagnosis;
      }
    }
    return latest;
  }

  CropActivityEntity? _lastCompletedActivity(List<CropActivityEntity> activities) {
    CropActivityEntity? lastCompleted;
    for (final activity in activities) {
      if (activity.status != ActivityStatus.completed) continue;
      if (lastCompleted == null ||
          activity.scheduledDate.isAfter(lastCompleted.scheduledDate)) {
        lastCompleted = activity;
      }
    }
    return lastCompleted;
  }
}

/// Secuencia generica de crecimiento usada solo para ubicar visualmente la
/// etapa real del cultivo (ver [AprendizHomeRepositoryImpl._stageIndexOf]).
enum CropGrowthStage { siembra, crecimiento, floracion, fruto, cosecha }
