import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../network/api_endpoints.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/error_interceptor.dart';
import '../network/interceptors/logging_interceptor.dart';
import '../storage/token_storage.dart';

// -- Parcelas/Cultivos --
import '../../features/agricultor/parcels/data/datasources/cultivos_remote_datasource.dart';
import '../../features/agricultor/parcels/data/repositories/parcel_repository_impl.dart';
import '../../features/agricultor/parcels/domain/repositories/parcel_repository.dart';
import '../../features/agricultor/parcels/domain/usecases/get_parcels_usecase.dart';
import '../../features/agricultor/parcels/domain/usecases/add_parcel_usecase.dart';
import '../../features/agricultor/parcels/domain/usecases/delete_parcel_usecase.dart';
import '../../features/agricultor/parcels/domain/usecases/get_cultivo_catalog_usecase.dart';
import '../../features/agricultor/parcels/presentation/bloc/parcel_bloc.dart';

// -- Auth --
import '../../features/login/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/login/auth/data/datasources/auth_local_datasource.dart';
import '../../features/login/auth/data/repositories/auth_repository_impl.dart';
import '../../features/login/auth/domain/repositories/auth_repository.dart';
import '../../features/login/auth/domain/usecases/login_usecase.dart';
import '../../features/login/auth/domain/usecases/register_usecase.dart';
import '../../features/login/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/login/auth/domain/usecases/logout_usecase.dart';
import '../../features/login/auth/domain/usecases/select_profile_type_usecase.dart';
import '../../features/login/auth/domain/usecases/get_saved_session_usecase.dart';
import '../../features/login/auth/domain/usecases/validate_register_form_usecase.dart';
import '../../features/login/auth/presentation/bloc/auth_bloc.dart';
import '../../features/login/auth/presentation/bloc/splash_cubit.dart';

// -- Home --
import '../../features/agricultor/home/data/datasources/home_remote_datasource.dart';
import '../../features/agricultor/home/data/repositories/home_repository_impl.dart';
import '../../features/agricultor/home/domain/repositories/home_repository.dart';
import '../../features/agricultor/home/domain/usecases/get_dashboard_usecase.dart';
import '../../features/agricultor/home/presentation/bloc/home_bloc.dart';

import '../../features/agricultor/diagnosis/data/datasources/diagnosis_remote_datasource.dart';
import '../../features/agricultor/diagnosis/data/datasources/llm_diagnosis_datasource.dart';
import '../../features/agricultor/diagnosis/data/datasources/product_remote_datasource.dart';
import '../../features/agricultor/diagnosis/data/repositories/diagnosis_repository_impl.dart';
import '../../features/agricultor/diagnosis/data/repositories/llm_diagnosis_repository_impl.dart';
import '../../features/agricultor/diagnosis/data/repositories/product_repository_impl.dart';
import '../../features/agricultor/diagnosis/domain/repositories/diagnosis_repository.dart';
import '../../features/agricultor/diagnosis/domain/repositories/llm_diagnosis_repository.dart';
import '../../features/agricultor/diagnosis/domain/repositories/product_repository.dart';
import '../../features/agricultor/diagnosis/domain/usecases/diagnosis_usecases.dart';
import '../../features/agricultor/diagnosis/domain/usecases/get_llm_diagnosis_usecase.dart';
import '../../features/agricultor/diagnosis/domain/usecases/get_recommended_products_usecase.dart';
import '../../features/agricultor/diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../features/agricultor/diagnosis/presentation/bloc/llm_diagnosis_cubit.dart';
import '../../features/agricultor/diagnosis/presentation/cubit/product_recommendation_cubit.dart';

// -- Treatment --
import '../../features/agricultor/treatment/data/datasources/treatment_local_datasource.dart';
import '../../features/agricultor/treatment/data/repositories/treatment_repository_impl.dart';
import '../../features/agricultor/treatment/domain/repositories/treatment_repository.dart';
import '../../features/agricultor/treatment/domain/usecases/treatment_usecases.dart';
import '../../features/agricultor/treatment/presentation/bloc/treatment_bloc.dart';

// -- Offline Mode --
import '../../features/agricultor/offline/data/datasources/offline_local_datasource.dart';
import '../../features/agricultor/offline/data/repositories/offline_repository_impl.dart';
import '../../features/agricultor/offline/domain/repositories/offline_repository.dart';
import '../../features/agricultor/offline/domain/usecases/offline_usecases.dart';
import '../../features/agricultor/offline/presentation/cubit/offline_cubit.dart';

// -- Aprendiz --
import '../../features/aprendiz/data/datasources/crop_plan_local_datasource.dart';
import '../../features/aprendiz/data/datasources/crop_plan_remote_datasource.dart';
import '../../features/aprendiz/data/repositories/crop_plan_repository_impl.dart';
import '../../features/aprendiz/domain/repositories/crop_plan_repository.dart';
import '../../features/aprendiz/domain/usecases/register_crop_plan_usecase.dart';
import '../../features/aprendiz/domain/usecases/get_saved_crop_plan_usecase.dart';
import '../../features/aprendiz/domain/usecases/get_crop_plan_progress_usecase.dart';
import '../../features/aprendiz/domain/usecases/get_crop_health_indicator_usecase.dart';
import '../../features/aprendiz/domain/usecases/complete_activity_usecase.dart';
import '../../features/aprendiz/domain/usecases/postpone_activity_usecase.dart';
import '../../features/aprendiz/domain/usecases/get_due_inspection_activity_usecase.dart';
import '../../features/aprendiz/presentation/bloc/aprendiz_home_cubit.dart';

import '../../features/aprendiz/data/datasources/crop_history_local_datasource.dart';
import '../../features/aprendiz/data/datasources/crop_history_remote_datasource.dart';
import '../../features/aprendiz/data/repositories/crop_history_repository_impl.dart';
import '../../features/aprendiz/domain/repositories/crop_history_repository.dart';
import '../../features/aprendiz/domain/usecases/get_crop_history_usecase.dart';
import '../../features/aprendiz/presentation/bloc/crop_history_bloc.dart';
import '../../features/aprendiz/domain/usecases/accept_guided_action_usecase.dart';
import '../../features/aprendiz/presentation/bloc/diagnosis_result_aprendiz_cubit.dart';
import '../../features/aprendiz/presentation/bloc/aprendiz_my_crop_cubit.dart';
import '../../features/aprendiz/domain/repositories/aprendiz_diagnosis_repository.dart';
import '../../features/aprendiz/data/repositories/aprendiz_diagnosis_repository_impl.dart';
import '../../features/aprendiz/data/datasources/aprendiz_diagnosis_local_datasource.dart';
import '../../features/aprendiz/data/datasources/aprendiz_diagnosis_history_local_datasource.dart';
import '../../features/aprendiz/domain/usecases/analyze_crop_aprendiz_usecase.dart';
import '../../features/aprendiz/domain/usecases/get_diagnosis_history_aprendiz_usecase.dart';
import '../../features/aprendiz/domain/usecases/save_diagnosis_llm_response_usecase.dart';
import '../../features/aprendiz/presentation/bloc/diagnosis_camera_aprendiz_cubit.dart';
import '../../features/aprendiz/presentation/bloc/aprendiz_diagnosis_history_cubit.dart';

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
  await _initOfflineFeature();
  _initAprendizFeature();
}

// =============================================================================
// CORE -- Network, Storage, Connectivity
// =============================================================================

Future<void> _initCore() async {
  // -- Local Storage: Hive Box compartida para Auth y TokenStorage --
  final authBox = await Hive.openBox<String>('auth_box');
  sl.registerLazySingleton<Box<String>>(() => authBox, instanceName: 'authBox');

  final diagnosisBox = await Hive.openBox<String>('diagnosis_history');
  sl.registerLazySingleton<Box<String>>(() => diagnosisBox, instanceName: 'diagnosisBox');

  // Nota: el historial de diagnósticos del perfil Aprendiz vive en SQLite
  // (tabla propia `aprendiz_diagnoses`, ver AprendizDiagnosisHistoryLocalDataSource),
  // no en Hive — se registra como datasource en _initAprendizFeature().

  final agendaBox = await Hive.openBox<String>('agenda_box');
  sl.registerLazySingleton<Box<String>>(() => agendaBox, instanceName: 'agendaBox');

  final seleccionesBox = await Hive.openBox<String>('selecciones_box');
  sl.registerLazySingleton<Box<String>>(() => seleccionesBox, instanceName: 'seleccionesBox');

  // -- Token Storage: acceso rápido a access/refresh token para el interceptor --
  sl.registerLazySingleton<TokenStorage>(
    () => TokenStorageImpl(sl<Box<String>>(instanceName: 'authBox')),
  );

  // -- Dio dedicado para renovar tokens (sin interceptores → evita loop) --
  final refreshDio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiEndpoints.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: ApiEndpoints.defaultTimeoutMs),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // -- Dio principal con interceptores --
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout:
            const Duration(milliseconds: ApiEndpoints.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: ApiEndpoints.defaultTimeoutMs),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      // 1. Enriquece mensajes de error antes de que lleguen a los datasources.
      ErrorInterceptor(),
      // 2. Inyecta el Bearer token y maneja el flujo 401 → refresh → retry.
      AuthInterceptor(
        tokenStorage: sl<TokenStorage>(),
        refreshDio: refreshDio,
      ),
      // 3. Log de requests/responses (solo en debug).
      LoggingInterceptor(),
    ]);

    return dio;
  });

  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  // -- Connectivity Monitor (offline-first) --
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
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
      tokenStorage: sl(),
    ),
  );

  // -- UseCases (Singleton: sin estado, reutilizables) --
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => SelectProfileTypeUseCase(sl()));
  sl.registerLazySingleton(() => GetSavedSessionUseCase(sl()));
  sl.registerLazySingleton(() => const ValidateRegisterFormUseCase());

  // -- Bloc (Factory: nueva instancia por pantalla) --
  sl.registerFactory(() => AuthBloc(
    loginUseCase: sl(),
    registerUseCase: sl(),
    getCurrentUserUseCase: sl(),
    logoutUseCase: sl(),
  ));
  
  sl.registerFactory(() => SplashCubit(
    getSavedSessionUseCase: sl(),
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
  sl.registerLazySingleton<DiagnosisRemoteDataSource>(
    () => DiagnosisRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<DiagnosisRepository>(
    () => DiagnosisRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton(() => AnalyzeCropUseCase(sl()));
  sl.registerLazySingleton(() => GetDiagnosisHistoryUseCase(sl()));

  sl.registerFactory(() => DiagnosisBloc(
        historyBox: sl<Box<String>>(instanceName: 'diagnosisBox'),
      ));

  // -- LLM/RAG: diagnóstico enriquecido (http://52.1.110.21:8000) --
  // Dio dedicado con timeout extendido (Ollama puede tardar hasta 120 s).
  sl.registerLazySingleton<Dio>(
    () {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout:
              const Duration(milliseconds: ApiEndpoints.connectTimeoutMs),
          receiveTimeout:
              const Duration(milliseconds: ApiEndpoints.defaultTimeoutMs),
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final llmDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.llmBaseUrl,
          connectTimeout:
              const Duration(milliseconds: ApiEndpoints.connectTimeoutMs),
          receiveTimeout:
              const Duration(milliseconds: ApiEndpoints.llmTimeoutMs),
          headers: {'Content-Type': 'application/json'},
        ),
      );
      llmDio.interceptors.addAll([
        ErrorInterceptor(),
        AuthInterceptor(tokenStorage: sl<TokenStorage>(), refreshDio: refreshDio),
        LoggingInterceptor(),
      ]);
      return llmDio;
    },
    instanceName: 'llmDio',
  );

  sl.registerLazySingleton<LlmDiagnosisDataSource>(
    () => LlmDiagnosisDataSourceImpl(sl<Dio>(instanceName: 'llmDio')),
  );

  sl.registerLazySingleton<LlmDiagnosisRepository>(
    () => LlmDiagnosisRepositoryImpl(
      dataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetLlmDiagnosisUseCase(sl()));

  sl.registerFactory(() => LlmDiagnosisCubit(sl()));

  // -- Productos: recomendaciones post-diagnóstico (http://44.196.107.153) --
  // Requiere X-API-Key + Authorization: Bearer <user_jwt>.
  // Usa TokenInjectInterceptor (sin refresh/clearTokens) para no invalidar
  // los tokens del usuario si este servidor devuelve 401.
  sl.registerLazySingleton<Dio>(
    () {
      final productsDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.productsBaseUrl,
          connectTimeout:
              const Duration(milliseconds: ApiEndpoints.connectTimeoutMs),
          receiveTimeout:
              const Duration(milliseconds: ApiEndpoints.productsTimeoutMs),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'X-API-Key': ApiEndpoints.productsApiKey,
          },
        ),
      );
      productsDio.interceptors.addAll([
        ErrorInterceptor(),
        LoggingInterceptor(),
      ]);
      return productsDio;
    },
    instanceName: 'productsDio',
  );

  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(sl<Dio>(instanceName: 'productsDio')),
  );

  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(dataSource: sl(), networkInfo: sl()),
  );

  sl.registerLazySingleton(() => GetRecommendedProductsUseCase(sl()));

  sl.registerFactory(() => ProductRecommendationCubit(sl()));
}

// =============================================================================
// FEATURE: TREATMENT (Agenda de Tratamiento)
// Stitch screen: decfe053...
// =============================================================================

void _initTreatmentFeature() {
  sl.registerLazySingleton<TreatmentLocalDataSource>(
    () => TreatmentLocalDataSourceImpl(
      diagnosisBox: sl<Box<String>>(instanceName: 'diagnosisBox'),
      agendaBox: sl<Box<String>>(instanceName: 'agendaBox'),
    ),
  );

  sl.registerLazySingleton<TreatmentRepository>(
    () => TreatmentRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetTreatmentAgendaUseCase(sl()));
  sl.registerLazySingleton(() => MarkStepCompleteUseCase(sl()));

  sl.registerFactory(() => TreatmentBloc(
    getAgendaUseCase: sl(),
    markStepCompleteUseCase: sl(),
  ));
}

// =============================================================================
// FEATURE: PARCELS/CULTIVOS (Mis Parcelas)
// Microservicio: http://3.217.217.227:8001/api/v1
// Mismo JWT del microservicio de Usuarios (clave compartida JWT_SECRET_KEY).
// =============================================================================

void _initParcelsFeature() {
  // -- Dio dedicado al microservicio de cultivos (baseUrl distinto) --
  // Comparte los mismos interceptores que el Dio principal para que el
  // AuthInterceptor inyecte el Bearer token en cada request.
  sl.registerLazySingleton<Dio>(
    () {
      final cultivosDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.cultivosBaseUrl,
          connectTimeout: const Duration(milliseconds: ApiEndpoints.connectTimeoutMs),
          receiveTimeout: const Duration(milliseconds: ApiEndpoints.defaultTimeoutMs),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      // Reutiliza el refreshDio de usuarios para el flujo 401 → refresh → retry.
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(milliseconds: ApiEndpoints.connectTimeoutMs),
          receiveTimeout: const Duration(milliseconds: ApiEndpoints.defaultTimeoutMs),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      cultivosDio.interceptors.addAll([
        ErrorInterceptor(),
        AuthInterceptor(tokenStorage: sl<TokenStorage>(), refreshDio: refreshDio),
        LoggingInterceptor(),
      ]);

      return cultivosDio;
    },
    instanceName: 'cultivosDio',
  );

  // -- DataSource --
  sl.registerLazySingleton<CultivosRemoteDataSource>(
    () => CultivosRemoteDataSourceImpl(
      client: sl<Dio>(instanceName: 'cultivosDio'),
      tokenStorage: sl<TokenStorage>(),
      seleccionesBox: sl<Box<String>>(instanceName: 'seleccionesBox'),
    ),
  );

  // -- Repository --
  sl.registerLazySingleton<ParcelRepository>(
    () => ParcelRepositoryImpl(remoteDataSource: sl()),
  );

  // -- UseCases --
  sl.registerLazySingleton(() => GetParcelsUseCase(sl()));
  sl.registerLazySingleton(() => AddParcelUseCase(sl()));
  sl.registerLazySingleton(() => DeleteParcelUseCase(sl()));
  sl.registerLazySingleton(() => GetCultivoCatalogUseCase(sl()));

  // -- Bloc (Factory: una instancia compartida via root MultiBlocProvider) --
  sl.registerFactory(() => ParcelBloc(
        getParcelsUseCase: sl(),
        addParcelUseCase: sl(),
        deleteParcelUseCase: sl(),
      ));
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

// =============================================================================
// FEATURE: OFFLINE MODE (Diagnóstico sin conexión + Top-K local)
// SQLite: agro_offline.db
// PUNTO DE INTEGRACIÓN LLM/RAG: ver OfflineLocalDataSource + OfflineRepository
// =============================================================================

Future<void> _initOfflineFeature() async {
  sl.registerLazySingleton<OfflineLocalDataSource>(
    () => OfflineLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<OfflineRepository>(
    () => OfflineRepositoryImpl(dataSource: sl()),
  );

  sl.registerLazySingleton(() => GetOfflineStatusUseCase(sl()));
  sl.registerLazySingleton(() => ToggleOfflineModeUseCase(sl()));
  sl.registerLazySingleton(() => GetOfflineCatalogUseCase(sl()));
  sl.registerLazySingleton(() => DownloadOfflineDocumentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteOfflineDocumentUseCase(sl()));

  sl.registerFactory(() => OfflineCubit(
        getStatusUseCase: sl(),
        toggleModeUseCase: sl(),
        getCatalogUseCase: sl(),
        downloadUseCase: sl(),
        deleteUseCase: sl(),
      ));
}

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

// =============================================================================
// FEATURE: APRENDIZ (Aprendiz Agrícola)
// =============================================================================

void _initAprendizFeature() {
  // DataSources
  sl.registerLazySingleton<CropPlanRemoteDataSource>(
    () => CropPlanRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<CropPlanLocalDataSource>(
    () => CropPlanLocalDataSourceImpl(box: sl(instanceName: 'authBox')), // TODO: Usar caja propia
  );

  // Repository
  sl.registerLazySingleton<CropPlanRepository>(
    () => CropPlanRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => RegisterCropPlanUseCase(sl()));
  sl.registerLazySingleton(() => GetSavedCropPlanUseCase(sl()));
  sl.registerLazySingleton(() => GetCropPlanProgressUseCase(sl()));
  sl.registerLazySingleton(() => GetCropHealthIndicatorUseCase(sl()));
  sl.registerLazySingleton(() => AnalyzeCropAprendizUseCase(sl()));
  sl.registerLazySingleton(() => CompleteActivityUseCase(sl()));
  sl.registerLazySingleton(() => PostponeActivityUseCase(sl()));
  sl.registerLazySingleton(() => GetDueInspectionActivityUseCase(sl()));
  
  // -- HISTORY --
  sl.registerLazySingleton<CropHistoryRemoteDataSource>(
    () => CropHistoryRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<CropHistoryLocalDataSource>(
    () => CropHistoryLocalDataSourceImpl(box: sl(instanceName: 'authBox')), // TODO
  );
  sl.registerLazySingleton<AprendizDiagnosisLocalDataSource>(
    () => AprendizDiagnosisLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<AprendizDiagnosisHistoryLocalDataSource>(
    () => AprendizDiagnosisHistoryLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<CropHistoryRepository>(
    () => CropHistoryRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<AprendizDiagnosisRepository>(
    () => AprendizDiagnosisRepositoryImpl(
      localDataSource: sl(),
      historyLocalDataSource: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetCropHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetDiagnosisHistoryAprendizUseCase(sl()));
  sl.registerLazySingleton(() => SaveDiagnosisLlmResponseUseCase(sl()));
  
  sl.registerLazySingleton(() => AcceptGuidedActionUseCase(
    completeActivityUseCase: sl(),
    cropPlanRepository: sl(),
  ));

  // Cubits
  sl.registerFactory(() => AprendizHomeCubit(
    getDueInspectionActivityUseCase: sl(),
    postponeActivityUseCase: sl(),
    getSavedCropPlanUseCase: sl(),
    getCropHealthIndicatorUseCase: sl(),
    networkInfo: sl(),
  ));
  
  sl.registerFactory(() => DiagnosisCameraAprendizCubit(
    analyzeCropUseCase: sl(),
  ));

  sl.registerFactory(() => CropHistoryBloc(
    getCropHistoryUseCase: sl(),
  ));
  sl.registerFactory(() => AprendizMyCropCubit(
    getSavedCropPlanUseCase: sl(),
    networkInfo: sl(),
  ));
  sl.registerFactory(() => DiagnosisResultAprendizCubit(
    acceptGuidedActionUseCase: sl(),
    saveDiagnosisLlmResponseUseCase: sl(),
  ));
  sl.registerFactory(() => AprendizDiagnosisHistoryCubit(
    getDiagnosisHistoryUseCase: sl(),
  ));
}
