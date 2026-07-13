import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../../../core/network/network_info.dart';
import '../data/datasources/agenda_local_datasource.dart';
import '../data/datasources/agenda_remote_datasource.dart';
import '../data/repositories/agenda_repository_impl.dart';
import '../domain/repositories/agenda_repository.dart';
import '../domain/usecases/complete_agenda_activity_usecase.dart';
import '../domain/usecases/generate_agenda_usecase.dart';
import '../domain/usecases/get_agenda_overview_usecase.dart';
import '../domain/usecases/postpone_agenda_activity_usecase.dart';
import '../presentation/bloc/agenda_bloc.dart';

/// Configuracion de inyeccion de dependencias propia del modulo Agenda.
///
/// El contenedor global (`core/di/injection_container.dart`) solo dispara
/// esta funcion; no conoce el detalle interno del modulo (caja Hive propia,
/// datasources, repositorio, casos de uso, bloc).
///
/// [AgendaRemoteDataSource] se registra aqui como singleton global (sin
/// nombre) porque es generico por rol -- `_initTreatmentFeature()` (Agricultor)
/// tambien lo reutiliza vía `sl<AgendaRemoteDataSource>()`, con su propia
/// caja Hive y su propia instancia de [AgendaRepository] (rol 'agricultor').
Future<void> initAgendaDependencies(GetIt sl) async {
  // -- Storage: caja Hive propia de Agenda del Aprendiz --
  final agendaBox = await Hive.openBox<String>('aprendiz_agenda_box');
  sl.registerLazySingleton<Box<String>>(
    () => agendaBox,
    instanceName: 'aprendizAgendaBox',
  );

  // -- DataSource remoto: generico por rol, reutiliza 'llmDio' (mismo host
  // que el backend de agenda, ver ApiEndpoints.agenda) --
  sl.registerLazySingleton<AgendaRemoteDataSource>(
    () => AgendaRemoteDataSourceImpl(client: sl<Dio>(instanceName: 'llmDio')),
  );
  sl.registerLazySingleton<AgendaLocalDataSource>(
    () => AgendaLocalDataSourceImpl(
      box: sl<Box<String>>(instanceName: 'aprendizAgendaBox'),
    ),
  );

  // -- Repository (rol 'aprendiz') --
  sl.registerLazySingleton<AgendaRepository>(
    () => AgendaRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl<NetworkInfo>(),
      rol: 'aprendiz',
    ),
  );

  // -- UseCases --
  sl.registerLazySingleton(() => GetAgendaOverviewUseCase(sl()));
  sl.registerLazySingleton(() => CompleteAgendaActivityUseCase(sl()));
  sl.registerLazySingleton(() => PostponeAgendaActivityUseCase(sl()));
  sl.registerLazySingleton(() => GenerateAgendaUseCase(sl()));

  // -- Bloc --
  sl.registerFactory(() => AgendaBloc(
        getAgendaOverviewUseCase: sl(),
        completeAgendaActivityUseCase: sl(),
        postponeAgendaActivityUseCase: sl(),
      ));
}
