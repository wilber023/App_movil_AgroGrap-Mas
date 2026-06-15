import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../network/api_endpoints.dart';
import '../network/network_info.dart';

// -- Auth --
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// -- Home --
import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_dashboard_usecase.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';

import '../../features/diagnosis/domain/usecases/diagnosis_usecases.dart';
import '../../features/diagnosis/presentation/bloc/diagnosis_bloc.dart';

// -- Treatment --
import '../../features/treatment/data/datasources/treatment_remote_datasource.dart';
import '../../features/treatment/data/repositories/treatment_repository_impl.dart';
import '../../features/treatment/domain/repositories/treatment_repository.dart';
import '../../features/treatment/domain/usecases/treatment_usecases.dart';
import '../../features/treatment/presentation/bloc/treatment_bloc.dart';

/// Instancia global del Service Locator.
final GetIt sl = GetIt.instance;

/// Inicializa todas las dependencias de la aplicacion.
///
/// Debe invocarse una unica vez en `main()` antes de `runApp()`.
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await initDependencies();
///   runApp(const AgroGraphApp());
/// }
/// ```
Future<void> initDependencies() async {
  await _initCore();
  _initAuthFeature();
  _initSubscriptionFeature();
  _initHomeFeature();
  _initDiagnosisFeature();
  _initTreatmentFeature();
  _initParcelsFeature();
  _initEconomicsFeature();
  _initProfileFeature();
}

// =============================================================================
// CORE -- Network, Storage, Connectivity
// =============================================================================

Future<void> _initCore() async {
  // -- HTTP Client --
  sl.registerLazySingleton<Dio>(() => Dio(BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: Duration(milliseconds: ApiEndpoints.connectTimeoutMs),
    receiveTimeout: Duration(milliseconds: ApiEndpoints.defaultTimeoutMs),
    headers: {'Content-Type': 'application/json'},
  )));

  // -- Connectivity Monitor (offline-first) --
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  // -- Local Storage: Hive Box para Auth --
  final authBox = await Hive.openBox<String>('auth_box');
  sl.registerLazySingleton<Box<String>>(() => authBox,
      instanceName: 'authBox');
}

// =============================================================================
// FEATURE: AUTH (Bienvenida, Registro de Cuenta)
// Stitch screens: 6a020f40..., ded05597...
// =============================================================================

void _initAuthFeature() {
  // -- DataSources (Singleton: compartidos en toda la app) --
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      authBox: sl<Box<String>>(instanceName: 'authBox'),
    ),
  );

  // -- Repository (Singleton: una sola instancia) --
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // -- UseCases (Singleton: sin estado, reutilizables) --
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // -- Bloc (Factory: nueva instancia por pantalla) --
  sl.registerFactory(() => AuthBloc(
    loginUseCase: sl(),
    registerUseCase: sl(),
    getCurrentUserUseCase: sl(),
    logoutUseCase: sl(),
  ));
}


// =============================================================================
// FEATURE: SUBSCRIPTION (Seleccion de Plan, Precios Plan Pro)
// Stitch screens: 1aedc88a..., e6279c20...
// =============================================================================

void _initSubscriptionFeature() {
  // -- DataSources --
  // sl.registerLazySingleton<SubscriptionRemoteDataSource>(
  //   () => SubscriptionRemoteDataSourceImpl(client: sl()),
  // );

  // -- Repository --
  // sl.registerLazySingleton<SubscriptionRepository>(
  //   () => SubscriptionRepositoryImpl(
  //     remoteDataSource: sl(),
  //     networkInfo: sl(),
  //   ),
  // );

  // -- UseCases --
  // sl.registerLazySingleton(() => GetPlansUseCase(sl()));
  // sl.registerLazySingleton(() => SubscribeToPlanUseCase(sl()));

  // -- Bloc --
  // sl.registerFactory(() => SubscriptionBloc(
  //   getPlansUseCase: sl(),
  //   subscribeToPlanUseCase: sl(),
  // ));
}

// =============================================================================
// FEATURE: HOME (Inicio / Dashboard)
// Stitch screen: 4995ecd9...
// =============================================================================

void _initHomeFeature() {
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetDashboardUseCase(sl()));

  sl.registerFactory(() => HomeBloc(
    getDashboardUseCase: sl(),
  ));
}

// =============================================================================
// FEATURE: DIAGNOSIS (Captura de Cultivo, Resultado del Diagnostico)
// Stitch screens: 32ae4671..., 71358cf2...
// =============================================================================

void _initDiagnosisFeature() {
  sl.registerLazySingleton(() => AnalyzeCropUseCase(sl()));
  sl.registerLazySingleton(() => GetDiagnosisHistoryUseCase(sl()));

  sl.registerFactory(() => DiagnosisBloc());
}

// =============================================================================
// FEATURE: TREATMENT (Agenda de Tratamiento)
// Stitch screen: decfe053...
// =============================================================================

void _initTreatmentFeature() {
  sl.registerLazySingleton<TreatmentRemoteDataSource>(
    () => TreatmentRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<TreatmentRepository>(
    () => TreatmentRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetTreatmentAgendaUseCase(sl()));
  sl.registerLazySingleton(() => MarkStepCompleteUseCase(sl()));

  sl.registerFactory(() => TreatmentBloc(
    getAgendaUseCase: sl(),
    markStepCompleteUseCase: sl(),
  ));
}

// =============================================================================
// FEATURE: PARCELS (Mis Parcelas)
// Stitch screen: 55e30d29...
// =============================================================================

void _initParcelsFeature() {
  // -- DataSources --
  // sl.registerLazySingleton<ParcelsRemoteDataSource>(
  //   () => ParcelsRemoteDataSourceImpl(client: sl()),
  // );
  // sl.registerLazySingleton<ParcelsLocalDataSource>(
  //   () => ParcelsLocalDataSourceImpl(storage: sl()),
  // );

  // -- Repository --
  // sl.registerLazySingleton<ParcelsRepository>(
  //   () => ParcelsRepositoryImpl(
  //     remoteDataSource: sl(),
  //     localDataSource: sl(),
  //     networkInfo: sl(),
  //   ),
  // );

  // -- UseCases --
  // sl.registerLazySingleton(() => GetParcelsUseCase(sl()));
  // sl.registerLazySingleton(() => GetParcelHealthUseCase(sl()));

  // -- Bloc --
  // sl.registerFactory(() => ParcelsBloc(
  //   getParcelsUseCase: sl(),
  //   getParcelHealthUseCase: sl(),
  // ));
}

// =============================================================================
// FEATURE: ECONOMICS (Analisis Economico)
// Stitch screen: a2fa3d1f...
// =============================================================================

void _initEconomicsFeature() {
  // -- DataSources --
  // sl.registerLazySingleton<EconomicsRemoteDataSource>(
  //   () => EconomicsRemoteDataSourceImpl(client: sl()),
  // );

  // -- Repository --
  // sl.registerLazySingleton<EconomicsRepository>(
  //   () => EconomicsRepositoryImpl(
  //     remoteDataSource: sl(),
  //     networkInfo: sl(),
  //   ),
  // );

  // -- UseCases --
  // sl.registerLazySingleton(() => GetEconomicsOverviewUseCase(sl()));

  // -- Bloc --
  // sl.registerFactory(() => EconomicsBloc(
  //   getEconomicsOverviewUseCase: sl(),
  // ));
}

// =============================================================================
// FEATURE: PROFILE (Perfil)
// Stitch screen: 2fd4aa99...
// =============================================================================

void _initProfileFeature() {
  // -- DataSources --
  // sl.registerLazySingleton<ProfileRemoteDataSource>(
  //   () => ProfileRemoteDataSourceImpl(client: sl()),
  // );
  // sl.registerLazySingleton<ProfileLocalDataSource>(
  //   () => ProfileLocalDataSourceImpl(storage: sl()),
  // );

  // -- Repository --
  // sl.registerLazySingleton<ProfileRepository>(
  //   () => ProfileRepositoryImpl(
  //     remoteDataSource: sl(),
  //     localDataSource: sl(),
  //     networkInfo: sl(),
  //   ),
  // );

  // -- UseCases --
  // sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  // sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));

  // -- Bloc --
  // sl.registerFactory(() => ProfileBloc(
  //   getProfileUseCase: sl(),
  //   updateProfileUseCase: sl(),
  // ));
}
