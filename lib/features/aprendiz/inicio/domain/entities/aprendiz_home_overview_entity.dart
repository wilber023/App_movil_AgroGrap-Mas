import 'package:equatable/equatable.dart';

import '../../../agenda/domain/entities/agenda_activity_entity.dart';
import '../../../cultivo/domain/entities/crop_activity_entity.dart';
import 'crop_catalog_item_entity.dart';
import 'crop_status_summary_entity.dart';
import 'home_notice_entity.dart';
import 'home_recommendation_entity.dart';
import 'phytosanitary_alert_entity.dart';
import 'recent_activity_item_entity.dart';

/// Agregado que la pantalla de Inicio necesita para renderizarse completa.
class AprendizHomeOverviewEntity extends Equatable {
  final String userName;
  final List<HomeNoticeEntity> notices;
  final PhytosanitaryAlertEntity phytosanitaryAlert;
  final AgendaActivityEntity? nextActivity;
  final CropStatusSummaryEntity cropStatus;
  final HomeRecommendationEntity recommendation;
  final List<RecentActivityItemEntity> recentActivity;

  /// Catalogo de cultivos disponibles (real, compartido con Registrar
  /// Cultivo), con el activo del usuario marcado.
  final List<CropCatalogItemEntity> cropCatalog;

  /// Actividades de agenda pendientes mas cercanas (real, subconjunto de
  /// `GetAgendaOverviewUseCase`), para la seccion "Tareas de hoy".
  final List<AgendaActivityEntity> upcomingTasks;

  /// Cantidad total de actividades pendientes en la agenda (real).
  final int pendingTasksCount;

  /// "Dato curioso" de la explicacion del diagnostico mas reciente
  /// (`llmResponse.explicacion`), si existe. Null si aun no hay ninguno.
  final String? funFact;

  /// Actividad de inspección vencida o programada para hoy, ya resuelta a
  /// partir del plan de cultivo (ver `resolveDueInspectionActivity`). Se
  /// expone aquí para que los consumidores (ej. `AprendizHomeBloc`) no
  /// tengan que volver a pedir el plan por red solo para calcular esto.
  final CropActivityEntity? dueInspection;

  const AprendizHomeOverviewEntity({
    required this.userName,
    required this.notices,
    required this.phytosanitaryAlert,
    required this.nextActivity,
    required this.cropStatus,
    required this.recommendation,
    required this.recentActivity,
    required this.cropCatalog,
    required this.upcomingTasks,
    required this.pendingTasksCount,
    required this.funFact,
    required this.dueInspection,
  });

  @override
  List<Object?> get props => [
        userName,
        notices,
        phytosanitaryAlert,
        nextActivity,
        cropStatus,
        recommendation,
        recentActivity,
        cropCatalog,
        upcomingTasks,
        pendingTasksCount,
        funFact,
        dueInspection,
      ];
}
