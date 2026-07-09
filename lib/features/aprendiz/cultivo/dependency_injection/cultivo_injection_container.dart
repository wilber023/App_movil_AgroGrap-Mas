import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../../../core/network/network_info.dart';
import '../data/datasources/crop_plan_local_datasource.dart';
import '../data/datasources/crop_plan_remote_datasource.dart';
import '../data/repositories/crop_plan_repository_impl.dart';
import '../domain/repositories/crop_plan_repository.dart';
import '../domain/usecases/complete_activity_usecase.dart';
import '../domain/usecases/get_crop_health_indicator_usecase.dart';
import '../domain/usecases/get_crop_plan_progress_usecase.dart';
import '../domain/usecases/get_due_inspection_activity_usecase.dart';
import '../domain/usecases/get_saved_crop_plan_usecase.dart';
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
  sl.registerLazySingleton<CropPlanRemoteDataSource>(
    () => CropPlanRemoteDataSourceImpl(apiClient: sl()),
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

  // -- Bloc --
  sl.registerFactory(() => CultivoBloc(
        getSavedCropPlanUseCase: sl(),
        registerCropPlanUseCase: sl(),
        networkInfo: sl<NetworkInfo>(),
      ));
}
