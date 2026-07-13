import 'package:get_it/get_it.dart';

import '../../../../core/network/network_info.dart';
import '../../../clustering/domain/usecases/get_alerta_usecase.dart';
import '../../../login/auth/domain/usecases/get_current_user_usecase.dart';
import '../../../notifications/domain/usecases/notification_preferences_usecases.dart';
import '../../agenda/domain/usecases/get_agenda_overview_usecase.dart';
import '../../cultivo/domain/usecases/get_crop_health_indicator_usecase.dart';
import '../../cultivo/domain/usecases/get_due_inspection_activity_usecase.dart';
import '../../cultivo/domain/usecases/get_saved_crop_plan_usecase.dart';
import '../../cultivo/domain/usecases/postpone_activity_usecase.dart';
import '../../diagnostico/domain/usecases/get_diagnosis_history_aprendiz_usecase.dart';
import '../data/repositories/aprendiz_home_repository_impl.dart';
import '../domain/repositories/aprendiz_home_repository.dart';
import '../domain/usecases/get_aprendiz_home_overview_usecase.dart';
import '../presentation/bloc/aprendiz_home_bloc.dart';

/// Configuracion de inyeccion de dependencias propia del modulo Inicio.
///
/// Se inicializa al final de `_initAprendizFeature()`, antes de
/// `_initNotificationsFeature()`/`_initClusteringFeature()` en
/// `initDependencies()` -- pero como todo aqui es lazy (`registerLazySingleton`
/// / `registerFactory`), el orden no importa: `GetAlertaUseCase` y
/// `GetNotificationPreferencesUseCase` solo se resuelven la primera vez que
/// se pide `AprendizHomeRepository`, ya con toda la app inicializada.
Future<void> initAprendizHomeDependencies(GetIt sl) async {
  // -- Repository --
  sl.registerLazySingleton<AprendizHomeRepository>(
    () => AprendizHomeRepositoryImpl(
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
      getSavedCropPlanUseCase: sl<GetSavedCropPlanUseCase>(),
      getDueInspectionActivityUseCase: sl<GetDueInspectionActivityUseCase>(),
      getCropHealthIndicatorUseCase: sl<GetCropHealthIndicatorUseCase>(),
      getDiagnosisHistoryUseCase: sl<GetDiagnosisHistoryAprendizUseCase>(),
      getAgendaOverviewUseCase: sl<GetAgendaOverviewUseCase>(),
      getAlertaUseCase: sl<GetAlertaUseCase>(),
      getNotificationPreferencesUseCase: sl<GetNotificationPreferencesUseCase>(),
    ),
  );

  // -- UseCases --
  sl.registerLazySingleton(() => GetAprendizHomeOverviewUseCase(sl()));

  // -- Bloc --
  sl.registerFactory(() => AprendizHomeBloc(
        getHomeOverviewUseCase: sl(),
        getDueInspectionActivityUseCase: sl<GetDueInspectionActivityUseCase>(),
        postponeActivityUseCase: sl<PostponeActivityUseCase>(),
        networkInfo: sl<NetworkInfo>(),
      ));
}
