import 'package:get_it/get_it.dart';

import '../../../../core/network/network_info.dart';
import '../../../login/auth/domain/usecases/get_current_user_usecase.dart';
import '../../agenda/domain/usecases/get_agenda_overview_usecase.dart';
import '../../cultivo/domain/usecases/get_crop_health_indicator_usecase.dart';
import '../../cultivo/domain/usecases/get_due_inspection_activity_usecase.dart';
import '../../cultivo/domain/usecases/get_saved_crop_plan_usecase.dart';
import '../../cultivo/domain/usecases/postpone_activity_usecase.dart';
import '../../diagnostico/domain/usecases/get_diagnosis_history_aprendiz_usecase.dart';
import '../data/datasources/phytosanitary_alert_local_datasource.dart';
import '../data/repositories/aprendiz_home_repository_impl.dart';
import '../domain/repositories/aprendiz_home_repository.dart';
import '../domain/usecases/get_aprendiz_home_overview_usecase.dart';
import '../presentation/bloc/aprendiz_home_bloc.dart';

/// Configuracion de inyeccion de dependencias propia del modulo Inicio.
///
/// Se inicializa al final de `_initAprendizFeature()` porque compone datos
/// de Auth, Cultivo, Diagnostico y Agenda (todos ya registrados en ese
/// punto): `GetCurrentUserUseCase`, `GetSavedCropPlanUseCase`,
/// `GetDueInspectionActivityUseCase`, `GetDiagnosisHistoryAprendizUseCase`
/// y `GetAgendaOverviewUseCase`.
Future<void> initAprendizHomeDependencies(GetIt sl) async {
  // -- DataSources --
  sl.registerLazySingleton<PhytosanitaryAlertLocalDataSource>(
    () => PhytosanitaryAlertLocalDataSourceImpl(),
  );

  // -- Repository --
  sl.registerLazySingleton<AprendizHomeRepository>(
    () => AprendizHomeRepositoryImpl(
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
      getSavedCropPlanUseCase: sl<GetSavedCropPlanUseCase>(),
      getDueInspectionActivityUseCase: sl<GetDueInspectionActivityUseCase>(),
      getCropHealthIndicatorUseCase: sl<GetCropHealthIndicatorUseCase>(),
      getDiagnosisHistoryUseCase: sl<GetDiagnosisHistoryAprendizUseCase>(),
      getAgendaOverviewUseCase: sl<GetAgendaOverviewUseCase>(),
      localDataSource: sl(),
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
