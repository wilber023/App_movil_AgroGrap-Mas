import 'package:get_it/get_it.dart';

import '../data/datasources/crop_history_local_datasource.dart';
import '../data/datasources/crop_history_remote_datasource.dart';
import '../data/repositories/crop_history_repository_impl.dart';
import '../domain/repositories/crop_history_repository.dart';
import '../domain/usecases/get_crop_history_usecase.dart';
import '../presentation/bloc/crop_history_bloc.dart';

/// Configuracion de inyeccion de dependencias propia del modulo Historial.
Future<void> initHistorialDependencies(GetIt sl) async {
  // -- DataSources --
  sl.registerLazySingleton<CropHistoryRemoteDataSource>(
    () => CropHistoryRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<CropHistoryLocalDataSource>(
    () => CropHistoryLocalDataSourceImpl(box: sl(instanceName: 'authBox')), // TODO
  );

  // -- Repository --
  sl.registerLazySingleton<CropHistoryRepository>(
    () => CropHistoryRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // -- UseCases --
  sl.registerLazySingleton(() => GetCropHistoryUseCase(sl()));

  // -- Bloc --
  sl.registerFactory(() => CropHistoryBloc(
        getCropHistoryUseCase: sl(),
      ));
}
