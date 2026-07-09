import 'package:get_it/get_it.dart';

import '../data/datasources/aprendiz_diagnosis_history_local_datasource.dart';
import '../data/datasources/aprendiz_diagnosis_local_datasource.dart';
import '../data/repositories/aprendiz_diagnosis_repository_impl.dart';
import '../domain/repositories/aprendiz_diagnosis_repository.dart';
import '../domain/usecases/accept_guided_action_usecase.dart';
import '../domain/usecases/analyze_crop_aprendiz_usecase.dart';
import '../domain/usecases/get_diagnosis_history_aprendiz_usecase.dart';
import '../domain/usecases/save_diagnosis_llm_response_usecase.dart';
import '../presentation/bloc/aprendiz_diagnosis_history_cubit.dart';
import '../presentation/bloc/diagnosis_camera_aprendiz_cubit.dart';
import '../presentation/bloc/diagnosis_result_aprendiz_cubit.dart';

/// Configuracion de inyeccion de dependencias propia del modulo Diagnostico.
///
/// El contenedor global (`core/di/injection_container.dart`) solo dispara
/// esta funcion; no conoce el detalle interno del modulo. El historial de
/// diagnosticos vive en su propia base SQLite (`aprendiz_diagnosis.db`, ver
/// `AprendizDiagnosisHistoryLocalDataSourceImpl`), ya aislada del resto de
/// la app, por lo que no requiere una caja Hive compartida como Agenda o
/// Cultivo.
void initDiagnosticoDependencies(GetIt sl) {
  // -- DataSources --
  sl.registerLazySingleton<AprendizDiagnosisLocalDataSource>(
    () => AprendizDiagnosisLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<AprendizDiagnosisHistoryLocalDataSource>(
    () => AprendizDiagnosisHistoryLocalDataSourceImpl(),
  );

  // -- Repository --
  sl.registerLazySingleton<AprendizDiagnosisRepository>(
    () => AprendizDiagnosisRepositoryImpl(
      localDataSource: sl(),
      historyLocalDataSource: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );

  // -- UseCases --
  sl.registerLazySingleton(() => AnalyzeCropAprendizUseCase(sl()));
  sl.registerLazySingleton(() => GetDiagnosisHistoryAprendizUseCase(sl()));
  sl.registerLazySingleton(() => SaveDiagnosisLlmResponseUseCase(sl()));
  sl.registerLazySingleton(() => AcceptGuidedActionUseCase(
        completeActivityUseCase: sl(),
        cropPlanRepository: sl(),
      ));

  // -- Cubits --
  sl.registerFactory(() => DiagnosisCameraAprendizCubit(analyzeCropUseCase: sl()));
  sl.registerFactory(() => AprendizDiagnosisHistoryCubit(getDiagnosisHistoryUseCase: sl()));
  sl.registerFactory(() => DiagnosisResultAprendizCubit(
        acceptGuidedActionUseCase: sl(),
        saveDiagnosisLlmResponseUseCase: sl(),
      ));
}
