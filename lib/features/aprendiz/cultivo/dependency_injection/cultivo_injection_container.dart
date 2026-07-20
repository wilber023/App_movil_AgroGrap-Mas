import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../../../core/network/network_info.dart';
import '../../agenda/domain/usecases/generate_agenda_usecase.dart';
import '../data/datasources/crop_plan_local_datasource.dart';
import '../data/datasources/crop_plan_remote_datasource.dart';
import '../data/repositories/crop_plan_repository_impl.dart';
import '../domain/repositories/crop_plan_repository.dart';
import '../domain/usecases/complete_activity_usecase.dart';
import '../domain/usecases/get_crop_health_indicator_usecase.dart';
import '../domain/usecases/get_crop_plan_progress_usecase.dart';
import '../domain/usecases/get_due_inspection_activity_usecase.dart';
import '../domain/usecases/get_saved_crop_plan_usecase.dart';
import '../domain/usecases/get_sowing_plan_text_usecase.dart';
import '../domain/usecases/postpone_activity_usecase.dart';
import '../domain/usecases/register_crop_plan_usecase.dart';
import '../presentation/bloc/cultivo_bloc.dart';

/// Configuracion de inyeccion de dependencias propia del modulo Mi Cultivo.
///
/// El contenedor global (`core/di/injection_container.dart`) solo dispara
/// esta funcion; no conoce el detalle interno del modulo. Se registra antes
/// que Inicio y Diagnostico porque ambos consumen casos de uso de Cultivo
/// (`GetSavedCropPlanUseCase`, `GetCropHealthIndicatorUseCase`,
/// `GetDueInspectionActivityUseCase`, `PostponeActivityUseCase`,
/// `CompleteActivityUseCase`, `CropPlanRepository`).
Future<void> initCultivoDependencies(GetIt sl) async {
  // -- Storage: caja Hive propia de Cultivo (independiente de Auth/Agenda) --
  final cultivoBox = await Hive.openBox<String>('aprendiz_cultivo_box');
  sl.registerLazySingleton<Box<String>>(
    () => cultivoBox,
    instanceName: 'aprendizCultivoBox',
  );

  // -- DataSources --
  // `cultivosDio` ya esta registrado por la feature Parcels (agricultor),
  // inicializada antes que Cultivo en `injection_container.dart`. `llmDio`
  // ya esta registrado por Diagnostico (Agricultor), tambien antes que
  // Cultivo. Ambos se reutilizan sin crear un nuevo Dio.
  sl.registerLazySingleton<CropPlanRemoteDataSource>(
    () => CropPlanRemoteDataSourceImpl(
      apiClient: sl(),
      cultivosClient: sl<Dio>(instanceName: 'cultivosDio'),
      llmClient: sl<Dio>(instanceName: 'llmDio'),
    ),
  );
  sl.registerLazySingleton<CropPlanLocalDataSource>(
    () => CropPlanLocalDataSourceImpl(
      box: sl<Box<String>>(instanceName: 'aprendizCultivoBox'),
    ),
  );

  // -- Repository --
  sl.registerLazySingleton<CropPlanRepository>(
    () => CropPlanRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // -- UseCases --
  sl.registerLazySingleton(() => RegisterCropPlanUseCase(sl()));
  sl.registerLazySingleton(() => GetSavedCropPlanUseCase(sl()));
  sl.registerLazySingleton(() => GetCropPlanProgressUseCase(sl()));
  sl.registerLazySingleton(() => GetCropHealthIndicatorUseCase(sl()));
  sl.registerLazySingleton(() => CompleteActivityUseCase(sl()));
  sl.registerLazySingleton(() => PostponeActivityUseCase(sl()));
  sl.registerLazySingleton(() => GetDueInspectionActivityUseCase(sl()));
  sl.registerLazySingleton(() => GetSowingPlanTextUseCase(sl()));

  // -- Bloc --
  // `GenerateAgendaUseCase` ya esta registrado por Agenda (inicializada
  // antes que Cultivo, ver `_initAprendizFeature()`): se reutiliza el mismo
  // caso de uso que ya usa el flujo de diagnostico, sin duplicar logica de
  // agenda.
  sl.registerFactory(() => CultivoBloc(
        getSavedCropPlanUseCase: sl(),
        registerCropPlanUseCase: sl(),
        getSowingPlanTextUseCase: sl(),
        generateAgendaUseCase: sl<GenerateAgendaUseCase>(),
        networkInfo: sl<NetworkInfo>(),
      ));
}
