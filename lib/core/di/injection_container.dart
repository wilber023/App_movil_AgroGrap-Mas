import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

// -- Treatment (agenda real de Agricultor, ver AgendaRepository/aprendiz/agenda) --
import '../../features/agricultor/treatment/data/datasources/treatment_local_datasource.dart';
import '../../features/agricultor/treatment/data/repositories/treatment_repository_impl.dart';
import '../../features/agricultor/treatment/domain/repositories/treatment_repository.dart';
import '../../features/agricultor/treatment/domain/usecases/treatment_usecases.dart';
import '../../features/agricultor/treatment/presentation/bloc/treatment_bloc.dart';
import '../../features/aprendiz/agenda/data/datasources/agenda_local_datasource.dart';
import '../../features/aprendiz/agenda/data/datasources/agenda_remote_datasource.dart';
import '../../features/aprendiz/agenda/data/repositories/agenda_repository_impl.dart';
import '../../features/aprendiz/agenda/domain/repositories/agenda_repository.dart';

// -- Offline Mode --
import '../../features/agricultor/offline/data/datasources/offline_local_datasource.dart';
import '../../features/agricultor/offline/data/repositories/offline_repository_impl.dart';
import '../../features/agricultor/offline/domain/repositories/offline_repository.dart';
import '../../features/agricultor/offline/domain/usecases/offline_usecases.dart';
import '../../features/agricultor/offline/presentation/cubit/offline_cubit.dart';

// -- Aprendiz / Agenda (modulo independiente, DI propia) --
import '../../features/aprendiz/agenda/dependency_injection/agenda_injection_container.dart';

// -- Aprendiz / Mi Cultivo (modulo independiente, DI propia) --
import '../../features/aprendiz/cultivo/dependency_injection/cultivo_injection_container.dart';

// -- Aprendiz / Diagnostico (modulo independiente, DI propia) --
import '../../features/aprendiz/diagnostico/dependency_injection/diagnostico_injection_container.dart';

// -- Aprendiz / Perfil (modulo independiente, DI propia) --
import '../../features/aprendiz/perfil/dependency_injection/perfil_injection_container.dart';

// -- Aprendiz / Inicio (modulo independiente, DI propia) --
import '../../features/aprendiz/inicio/dependency_injection/aprendiz_home_injection_container.dart';

// -- Aprendiz / Historial (modulo independiente, DI propia) --
import '../../features/aprendiz/historial/dependency_injection/historial_injection_container.dart';

// -- Offline Knowledge (diagnóstico offline por embeddings, 100% aditiva) --
import '../../features/offline_knowledge/data/datasources/embedding_model_datasource.dart';
import '../../features/offline_knowledge/data/datasources/knowledge_local_datasource.dart';
import '../../features/offline_knowledge/data/datasources/knowledge_remote_datasource.dart';
import '../../features/offline_knowledge/data/repositories/knowledge_repository_impl.dart';
import '../../features/offline_knowledge/domain/repositories/knowledge_repository.dart';
import '../../features/offline_knowledge/domain/usecases/get_offline_diagnosis_detail_usecase.dart';
import '../../features/offline_knowledge/presentation/cubit/offline_knowledge_cubit.dart';
import '../../features/offline_knowledge/presentation/cubit/offline_package_manager_cubit.dart';

// -- Subscription --
import '../../features/subscription/data/datasources/subscription_remote_datasource.dart';
import '../../features/subscription/data/repositories/subscription_repository_impl.dart';
import '../../features/subscription/domain/repositories/subscription_repository.dart';
import '../../features/subscription/domain/usecases/cancel_subscription_usecase.dart';
import '../../features/subscription/domain/usecases/get_subscription_status_usecase.dart';
import '../../features/subscription/domain/usecases/subscribe_usecase.dart';
import '../../features/subscription/presentation/bloc/subscription_bloc.dart';

// -- Notifications (FCM + historial local) --
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/datasources/notification_local_datasource.dart';
import '../../features/notifications/data/repositories/notification_subscription_repository_impl.dart';
import '../../features/notifications/data/repositories/notification_history_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_subscription_repository.dart';
import '../../features/notifications/domain/repositories/notification_history_repository.dart';
import '../../features/notifications/domain/usecases/subscribe_to_alerts_usecase.dart';
import '../../features/notifications/domain/usecases/get_alert_subscription_usecase.dart';
import '../../features/notifications/domain/usecases/cancel_alert_subscription_usecase.dart';
import '../../features/notifications/domain/usecases/get_notification_history_usecase.dart';
import '../../features/notifications/domain/usecases/save_notification_usecase.dart';
import '../../features/notifications/domain/usecases/notification_preferences_usecases.dart';
import '../../features/notifications/presentation/bloc/notification_subscription_bloc.dart';
import '../../features/notifications/presentation/cubit/notification_history_cubit.dart';

// -- Clustering (Mapa epidemiológico -- mismo host que LLM/RAG) --
import '../../features/clustering/data/datasources/clustering_remote_datasource.dart';
import '../../features/clustering/data/repositories/clustering_repository_impl.dart';
import '../../features/clustering/domain/repositories/clustering_repository.dart';
import '../../features/clustering/domain/usecases/get_alerta_usecase.dart';
import '../../features/clustering/domain/usecases/get_mapa_campanias_usecase.dart';
import '../../features/clustering/presentation/cubit/epidemiological_alert_cubit.dart';
import '../../features/clustering/presentation/cubit/epidemiological_map_cubit.dart';

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
  _initOfflineKnowledgeFeature();
  await _initAprendizFeature();
  _initNotificationsFeature();
  _initClusteringFeature();
}

// =============================================================================
// CORE -- Network, Storage, Connectivity
// =============================================================================

Future<void> _initCore() async {
  // -- Local Storage: Hive Box compartida para Auth y TokenStorage --
  final authBox = await Hive.openBox<String>('auth_box');
  sl.registerLazySingleton<Box<String>>(() => authBox, instanceName: 'authBox');

  final diagnosisBox = await Hive.openBox<String>('diagnosis_history');
  sl.registerLazySingleton<Box<String>>(
    () => diagnosisBox,
    instanceName: 'diagnosisBox',
  );

  // Nota: el historial de diagnósticos del perfil Aprendiz vive en SQLite
  // (tabla propia `aprendiz_diagnoses`, ver AprendizDiagnosisHistoryLocalDataSource),
  // no en Hive — se registra como datasource en _initAprendizFeature().

  final agendaBox = await Hive.openBox<String>('agenda_box');
  sl.registerLazySingleton<Box<String>>(
    () => agendaBox,
    instanceName: 'agendaBox',
  );

  final seleccionesBox = await Hive.openBox<String>('selecciones_box');
  sl.registerLazySingleton<Box<String>>(
    () => seleccionesBox,
    instanceName: 'seleccionesBox',
  );

  final notificationsBox = await Hive.openBox<String>('notifications_box');
  sl.registerLazySingleton<Box<String>>(
    () => notificationsBox,
    instanceName: 'notificationsBox',
  );

  // -- Secure Storage: Keystore (Android) / Keychain (iOS) --
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  // -- Token Storage: acceso rápido a access/refresh token para el interceptor --
  // MASVS-STORAGE: los tokens ya NO viven en el Hive Box (texto plano),
  // sino en flutter_secure_storage (ver core/storage/token_storage.dart).
  sl.registerLazySingleton<TokenStorage>(
    () => TokenStorageImpl(sl<FlutterSecureStorage>()),
  );

  // -- Dio dedicado para renovar tokens (sin interceptores → evita loop) --
  final refreshDio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(
        milliseconds: ApiEndpoints.connectTimeoutMs,
      ),
      receiveTimeout: const Duration(
        milliseconds: ApiEndpoints.defaultTimeoutMs,
      ),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // -- Dio principal con interceptores --
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiEndpoints.connectTimeoutMs,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiEndpoints.defaultTimeoutMs,
        ),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      // 1. Enriquece mensajes de error antes de que lleguen a los datasources.
      ErrorInterceptor(),
      // 2. Inyecta el Bearer token y maneja el flujo 401 → refresh → retry.
      AuthInterceptor(tokenStorage: sl<TokenStorage>(), refreshDio: refreshDio),
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
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      getCurrentUserUseCase: sl(),
      logoutUseCase: sl(),
    ),
  );

  sl.registerFactory(() => SplashCubit(getSavedSessionUseCase: sl()));
}

// =============================================================================
// FEATURE: SUBSCRIPTION (Seleccion de Plan, Precios Plan Pro)
// Stitch screens: 1aedc88a..., e6279c20...
// =============================================================================

void _initSubscriptionFeature() {
  // -- DataSource --
  // Reutiliza el Dio principal (mismo AuthInterceptor/ErrorInterceptor/
  // LoggingInterceptor, mismos timeouts y headers que el resto de la app;
  // ver _initCore()). No se registra un Dio dedicado para esta feature:
  // un segundo AuthInterceptor con su propio flag `_isRefreshing` podia
  // competir en paralelo por renovar el token y disparar un logout
  // espurio. El microservicio de pagos vive en un host distinto, por lo
  // que el datasource pide cada endpoint con URL absoluta (ver
  // SubscriptionRemoteDataSourceImpl._url), que Dio respeta sin perder
  // los interceptores del cliente compartido.
  sl.registerLazySingleton<SubscriptionRemoteDataSource>(
    () => SubscriptionRemoteDataSourceImpl(client: sl()),
  );

  // -- Repository --
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(remoteDataSource: sl()),
  );

  // -- UseCases --
  sl.registerLazySingleton(() => SubscribeUseCase(sl()));
  sl.registerLazySingleton(() => GetSubscriptionStatusUseCase(sl()));
  sl.registerLazySingleton(() => CancelSubscriptionUseCase(sl()));

  // -- Bloc --
  sl.registerFactory(
    () => SubscriptionBloc(
      subscribeUseCase: sl(),
      getSubscriptionStatusUseCase: sl(),
      cancelSubscriptionUseCase: sl(),
    ),
  );
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
    () => HomeRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  sl.registerLazySingleton(() => GetDashboardUseCase(sl()));

  sl.registerFactory(() => HomeBloc(getDashboardUseCase: sl()));
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
    () => DiagnosisRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  sl.registerLazySingleton(() => AnalyzeCropUseCase(sl()));
  sl.registerLazySingleton(() => GetDiagnosisHistoryUseCase(sl()));

  sl.registerFactory(
    () => DiagnosisBloc(
      historyBox: sl<Box<String>>(instanceName: 'diagnosisBox'),
    ),
  );

  // -- LLM/RAG: diagnóstico enriquecido (http://52.1.110.21:8000) --
  // Dio dedicado con timeout extendido (Ollama puede tardar hasta 120 s).
  sl.registerLazySingleton<Dio>(() {
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiEndpoints.connectTimeoutMs,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiEndpoints.defaultTimeoutMs,
        ),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    final llmDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.llmBaseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiEndpoints.connectTimeoutMs,
        ),
        receiveTimeout: const Duration(milliseconds: ApiEndpoints.llmTimeoutMs),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    llmDio.interceptors.addAll([
      ErrorInterceptor(),
      AuthInterceptor(tokenStorage: sl<TokenStorage>(), refreshDio: refreshDio),
      LoggingInterceptor(),
    ]);
    return llmDio;
  }, instanceName: 'llmDio');

  sl.registerLazySingleton<LlmDiagnosisDataSource>(
    () => LlmDiagnosisDataSourceImpl(sl<Dio>(instanceName: 'llmDio')),
  );

  sl.registerLazySingleton<LlmDiagnosisRepository>(
    () => LlmDiagnosisRepositoryImpl(dataSource: sl(), networkInfo: sl()),
  );

  sl.registerLazySingleton(() => GetLlmDiagnosisUseCase(sl()));

  sl.registerFactory(() => LlmDiagnosisCubit(sl()));

  // -- Productos: recomendaciones post-diagnóstico (http://44.196.107.153) --
  // Requiere X-API-Key + Authorization: Bearer <user_jwt>.
  // Usa TokenInjectInterceptor (sin refresh/clearTokens) para no invalidar
  // los tokens del usuario si este servidor devuelve 401.
  sl.registerLazySingleton<Dio>(() {
    final productsDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.productsBaseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiEndpoints.connectTimeoutMs,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiEndpoints.productsTimeoutMs,
        ),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-API-Key': ApiEndpoints.productsApiKey,
        },
      ),
    );
    productsDio.interceptors.addAll([ErrorInterceptor(), LoggingInterceptor()]);
    return productsDio;
  }, instanceName: 'productsDio');

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
      agendaBox: sl<Box<String>>(instanceName: 'agendaBox'),
    ),
  );

  // -- Agenda real del Agricultor (rol 'agricultor'): reutiliza el mismo
  // AgendaRemoteDataSource generico que Aprendiz (ver
  // initAgendaDependencies), con su propia cache local en 'agendaBox' (ya
  // registrada arriba, sin colisionar claves con el resto de Treatment) --
  sl.registerLazySingleton<AgendaLocalDataSource>(
    () => AgendaLocalDataSourceImpl(box: sl<Box<String>>(instanceName: 'agendaBox')),
    instanceName: 'agricultorAgendaLocalDataSource',
  );
  sl.registerLazySingleton<AgendaRepository>(
    () => AgendaRepositoryImpl(
      remoteDataSource: sl<AgendaRemoteDataSource>(),
      localDataSource: sl<AgendaLocalDataSource>(instanceName: 'agricultorAgendaLocalDataSource'),
      networkInfo: sl<NetworkInfo>(),
      rol: 'agricultor',
    ),
    instanceName: 'agricultorAgendaRepository',
  );

  sl.registerLazySingleton<TreatmentRepository>(
    () => TreatmentRepositoryImpl(
      agendaRepository: sl<AgendaRepository>(instanceName: 'agricultorAgendaRepository'),
      localDataSource: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetTreatmentAgendaUseCase(sl()));
  sl.registerLazySingleton(() => GenerateTreatmentFromDiagnosisUseCase(sl()));
  sl.registerLazySingleton(() => IsActivePlanForUseCase(sl()));
  sl.registerLazySingleton(() => MarkStepCompleteUseCase(sl()));
  sl.registerLazySingleton(() => RescheduleStepUseCase(sl()));
  sl.registerLazySingleton(() => SetRemindersActiveUseCase(sl()));

  sl.registerFactory(
    () => TreatmentBloc(
      getAgendaUseCase: sl(),
      generateFromDiagnosisUseCase: sl(),
      markStepCompleteUseCase: sl(),
      rescheduleStepUseCase: sl(),
      setRemindersActiveUseCase: sl(),
    ),
  );
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
  sl.registerLazySingleton<Dio>(() {
    final cultivosDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.cultivosBaseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiEndpoints.connectTimeoutMs,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiEndpoints.defaultTimeoutMs,
        ),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Reutiliza el refreshDio de usuarios para el flujo 401 → refresh → retry.
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiEndpoints.connectTimeoutMs,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiEndpoints.defaultTimeoutMs,
        ),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    cultivosDio.interceptors.addAll([
      ErrorInterceptor(),
      AuthInterceptor(tokenStorage: sl<TokenStorage>(), refreshDio: refreshDio),
      LoggingInterceptor(),
    ]);

    return cultivosDio;
  }, instanceName: 'cultivosDio');

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
  sl.registerFactory(
    () => ParcelBloc(
      getParcelsUseCase: sl(),
      addParcelUseCase: sl(),
      deleteParcelUseCase: sl(),
    ),
  );
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

  sl.registerFactory(
    () => OfflineCubit(
      getStatusUseCase: sl(),
      toggleModeUseCase: sl(),
      getCatalogUseCase: sl(),
      downloadUseCase: sl(),
      deleteUseCase: sl(),
    ),
  );
}

// =============================================================================
// FEATURE: OFFLINE KNOWLEDGE (fallback offline por embeddings, 100% aditiva)
// SQLite propia: agro_knowledge.db (independiente de agro_offline.db).
// No toca core/network/ ni el flujo online existente de diagnosis/.
// =============================================================================

void _initOfflineKnowledgeFeature() {
  sl.registerLazySingleton<EmbeddingModelDataSource>(
    () => EmbeddingModelDataSourceImpl(),
  );

  sl.registerLazySingleton<KnowledgeLocalDataSource>(
    () => KnowledgeLocalDataSourceImpl(),
  );

  // Reutiliza el Dio compartido ya registrado en _initCore() (con
  // AuthInterceptor/ErrorInterceptor/LoggingInterceptor) — mismo patrón que
  // SubscriptionRemoteDataSourceImpl: URL absoluta hacia un host distinto,
  // sin crear una instancia de Dio dedicada. No usa ApiClient porque este
  // backend no envuelve sus respuestas en {success, data, error} (ver
  // README_ofline.md y offline_knowledge_implementacion.md, Sprint 3).
  sl.registerLazySingleton<KnowledgeRemoteDataSource>(
    () => KnowledgeRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<KnowledgeRepository>(
    () => KnowledgeRepositoryImpl(localDataSource: sl(), remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetOfflineDiagnosisDetailUseCase(sl(), sl()));

  sl.registerFactory(() => OfflineKnowledgeCubit(sl()));
  sl.registerFactory(() => OfflinePackageManagerCubit(sl()));
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

Future<void> _initAprendizFeature() async {
  // -- Agenda, Mi Cultivo, Diagnostico, Perfil, Inicio e Historial: modulos
  // independientes, cada uno con su propia configuracion de DI. Cultivo se
  // inicializa antes porque Diagnostico (AcceptGuidedActionUseCase),
  // Perfil e Inicio consumen sus casos de uso/repositorio. Inicio se
  // inicializa despues de esos cuatro porque compone sus datos; Historial
  // no depende de ningun otro modulo.
  await initAgendaDependencies(sl);
  await initCultivoDependencies(sl);
  initDiagnosticoDependencies(sl);
  await initPerfilDependencies(sl);
  await initAprendizHomeDependencies(sl);
  await initHistorialDependencies(sl);
}

// =============================================================================
// FEATURE: NOTIFICATIONS (Suscripción a alertas push / FCM + historial local)
// Microservicio: http://3.218.172.128:8100 (ver integrar_notificaciones.md)
// Compartida entre Agricultor y Aprendiz (misma pantalla, mismo componente).
// =============================================================================

void _initNotificationsFeature() {
  // -- DataSources --
  // Reutiliza el Dio principal (mismo patron que Subscription/Offline
  // Knowledge): el backend de notificaciones solo necesita el JWT
  // compartido, sin headers/timeouts especiales — no se crea un Dio
  // dedicado, para no duplicar el AuthInterceptor.
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<NotificationLocalDataSource>(
    () => NotificationLocalDataSourceImpl(
      box: sl<Box<String>>(instanceName: 'notificationsBox'),
    ),
  );

  // -- Repositories --
  sl.registerLazySingleton<NotificationSubscriptionRepository>(
    () => NotificationSubscriptionRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<NotificationHistoryRepository>(
    () => NotificationHistoryRepositoryImpl(localDataSource: sl()),
  );

  // -- UseCases --
  sl.registerLazySingleton(() => SubscribeToAlertsUseCase(sl()));
  sl.registerLazySingleton(() => GetAlertSubscriptionUseCase(sl()));
  sl.registerLazySingleton(() => CancelAlertSubscriptionUseCase(sl()));
  sl.registerLazySingleton(() => GetNotificationHistoryUseCase(sl()));
  sl.registerLazySingleton(() => SaveNotificationUseCase(sl()));
  sl.registerLazySingleton(() => GetNotificationPreferencesUseCase(sl()));
  sl.registerLazySingleton(() => SaveNotificationPreferencesUseCase(sl()));

  // -- Bloc/Cubit (Factory: nueva instancia por pantalla) --
  sl.registerFactory(
    () => NotificationSubscriptionBloc(
      subscribeUseCase: sl(),
      cancelUseCase: sl(),
      getPreferencesUseCase: sl(),
      savePreferencesUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => NotificationHistoryCubit(getHistoryUseCase: sl()),
  );
}

// =============================================================================
// CLUSTERING -- Mapa epidemiológico (http://52.1.110.21:8000, mismo host y
// Dio 'llmDio' que el diagnóstico LLM/RAG -- ver _initDiagnosisFeature()).
// =============================================================================

void _initClusteringFeature() {
  // -- DataSource --
  sl.registerLazySingleton<ClusteringRemoteDataSource>(
    () => ClusteringRemoteDataSourceImpl(client: sl<Dio>(instanceName: 'llmDio')),
  );

  // -- Repository --
  sl.registerLazySingleton<ClusteringRepository>(
    () => ClusteringRepositoryImpl(remoteDataSource: sl()),
  );

  // -- UseCases --
  sl.registerLazySingleton(() => GetMapaCampaniasUseCase(sl()));
  sl.registerLazySingleton(() => GetAlertaUseCase(sl()));

  // -- Cubits (Factory: nueva instancia por pantalla) --
  sl.registerFactory(
    () => EpidemiologicalMapCubit(getMapaCampaniasUseCase: sl()),
  );
  sl.registerFactory(
    () => EpidemiologicalAlertCubit(
      getAlertaUseCase: sl(),
      getNotificationPreferencesUseCase: sl(),
    ),
  );
}
