import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../../../core/network/network_info.dart';
import '../../../login/auth/domain/usecases/get_current_user_usecase.dart';
import '../../cultivo/domain/usecases/get_saved_crop_plan_usecase.dart';
import '../../diagnostico/domain/usecases/get_diagnosis_history_aprendiz_usecase.dart';
import '../data/datasources/aprendiz_profile_local_datasource.dart';
import '../data/datasources/aprendiz_profile_remote_datasource.dart';
import '../data/repositories/aprendiz_profile_repository_impl.dart';
import '../domain/repositories/aprendiz_profile_repository.dart';
import '../domain/usecases/get_aprendiz_profile_overview_usecase.dart';
import '../domain/usecases/get_offline_mode_usecase.dart';
import '../domain/usecases/set_offline_mode_usecase.dart';
import '../presentation/bloc/aprendiz_profile_bloc.dart';

/// Configuracion de inyeccion de dependencias propia del modulo Perfil.
///
/// Se inicializa despues de Cultivo y Diagnostico porque compone datos de
/// ambos (`GetSavedCropPlanUseCase`, `GetDiagnosisHistoryAprendizUseCase`)
/// junto con `GetCurrentUserUseCase` de Auth (ya registrado por
/// `_initAuthFeature`).
Future<void> initPerfilDependencies(GetIt sl) async {
  // -- Storage: caja Hive propia de Perfil (ajustes locales) --
  final perfilBox = await Hive.openBox<String>('aprendiz_perfil_box');
  sl.registerLazySingleton<Box<String>>(
    () => perfilBox,
    instanceName: 'aprendizPerfilBox',
  );

  // -- DataSources --
  sl.registerLazySingleton<AprendizProfileRemoteDataSource>(
    () => AprendizProfileRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<AprendizProfileLocalDataSource>(
    () => AprendizProfileLocalDataSourceImpl(
      box: sl<Box<String>>(instanceName: 'aprendizPerfilBox'),
    ),
  );

  // -- Repository --
  sl.registerLazySingleton<AprendizProfileRepository>(
    () => AprendizProfileRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
      getSavedCropPlanUseCase: sl<GetSavedCropPlanUseCase>(),
      getDiagnosisHistoryUseCase: sl<GetDiagnosisHistoryAprendizUseCase>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // -- UseCases --
  sl.registerLazySingleton(() => GetAprendizProfileOverviewUseCase(sl()));
  sl.registerLazySingleton(() => GetOfflineModeUseCase(sl()));
  sl.registerLazySingleton(() => SetOfflineModeUseCase(sl()));

  // -- Bloc --
  sl.registerFactory(() => AprendizProfileBloc(
        getProfileOverviewUseCase: sl(),
        setOfflineModeUseCase: sl(),
      ));
}
