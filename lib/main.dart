import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/injection_container.dart';
import 'core/services/fcm_background_handler.dart';
import 'core/services/push_notification_service.dart';
import 'core/session/session_manager.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/usecases/usecase.dart';
import 'features/login/auth/presentation/bloc/auth_bloc.dart';
import 'features/login/auth/presentation/bloc/auth_event.dart';
import 'features/login/auth/presentation/bloc/auth_state.dart';
import 'features/login/auth/presentation/pages/select_profile_page.dart';
import 'features/login/auth/presentation/pages/splash_page.dart';
import 'features/notifications/domain/usecases/cancel_alert_subscription_usecase.dart';
import 'features/notifications/domain/usecases/notification_preferences_usecases.dart';
import 'features/notifications/domain/usecases/subscribe_to_alerts_usecase.dart';
import 'features/agricultor/diagnosis/presentation/bloc/diagnosis_bloc.dart';
import 'features/agricultor/diagnosis/presentation/pages/diagnosis_page.dart';
import 'features/agricultor/home/presentation/bloc/home_bloc.dart';
import 'features/agricultor/home/presentation/pages/home_page.dart';
import 'features/agricultor/profile/presentation/pages/profile_page.dart';
import 'features/agricultor/parcels/presentation/pages/parcels_page.dart';
import 'features/agricultor/parcels/presentation/bloc/parcel_bloc.dart';
import 'features/agricultor/parcels/domain/usecases/get_parcels_usecase.dart';
import 'features/agricultor/offline/presentation/cubit/offline_cubit.dart';
import 'features/agricultor/treatment/presentation/bloc/treatment_bloc.dart';
import 'features/agricultor/treatment/presentation/pages/treatment_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  await Hive.initFlutter();
  await initDependencies();

  // Notificaciones push (FCM) -- unicamente Android, ver
  // integrar_notificaciones.md. Envuelto en try/catch: mientras
  // android/app/google-services.json no exista (o sea invalido), la app
  // debe arrancar normalmente con el push simplemente inactivo.
  if (Platform.isAndroid) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await PushNotificationService(
        saveNotificationUseCase: sl(),
        getPreferencesUseCase: sl(),
        savePreferencesUseCase: sl(),
        subscribeUseCase: sl(),
        navigatorKey: AgroGraphApp.navigatorKey,
      ).init();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Inicialización falló (¿falta google-services.json?): $e');
      }
    }
  }

  runApp(const AgroGraphApp());
}

class AgroGraphApp extends StatefulWidget {
  const AgroGraphApp({super.key});

  /// Navigator raiz, accesible sin BuildContext. Lo usa el listener de
  /// [SessionManager] para volver a SelectProfilePage cuando el refresh
  /// token tambien falla en medio de una sesion ya activa (ver
  /// _AgroGraphAppState.initState).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<AgroGraphApp> createState() => _AgroGraphAppState();
}

class _AgroGraphAppState extends State<AgroGraphApp> {
  StreamSubscription<void>? _sessionInvalidatedSubscription;

  @override
  void initState() {
    super.initState();
    _sessionInvalidatedSubscription =
        SessionManager.instance.onSessionInvalidated.listen((_) {
      AgroGraphApp.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SelectProfilePage()),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _sessionInvalidatedSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Notificaciones push -- re-suscripcion/cancelacion best-effort en cada
  // cambio de sesion (ver integrar_notificaciones.md: "cuando el usuario
  // cierra sesion: eliminar la suscripcion"; "si el usuario cambia de
  // cuenta: actualizar la suscripcion"). Nunca bloquea ni rompe el flujo de
  // login/logout: cualquier error solo se loguea en debug.
  // ---------------------------------------------------------------------------

  Future<void> _onLoggedIn() async {
    // Precalienta la caché local de parcelas (Región/Comunidad) apenas hay
    // sesión activa -- fresh login o sesión restaurada, da igual. El reporte
    // de diagnóstico a Clustering lee esa caché sin red (nunca puede
    // consultar el microservicio de Cultivos al momento del diagnóstico),
    // así que debe quedar poblada ANTES de que el usuario alcance a
    // diagnosticar, sin depender de que primero visite Inicio/Mis Parcelas.
    // Nunca bloquea la navegación ni el login: solo agricultor tiene
    // parcelas, y cualquier error se descarta en silencio.
    unawaited(_warmUpParcelsCache());

    if (!Platform.isAndroid) return;
    try {
      final prefsResult = await sl<GetNotificationPreferencesUseCase>()(const NoParams());
      await prefsResult.fold(
        (_) async {},
        (prefs) async {
          if (!prefs.enabled || prefs.estado.isEmpty) return;
          final token = await FirebaseMessaging.instance.getToken();
          if (token == null) return;
          final result = await sl<SubscribeToAlertsUseCase>()(SubscribeParams(
            fcmToken: token,
            estado: prefs.estado,
            cultivos: prefs.cultivos,
          ));
          // Re-suscripcion exitosa en segundo plano: refleja que ya no hay
          // nada pendiente de sincronizar (ver notificaciones_fix.md).
          if (result.isRight()) {
            await sl<SaveNotificationPreferencesUseCase>()(prefs.copyWith(pushSyncPending: false));
          }
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Re-suscripción tras login falló: $e');
    }
  }

  Future<void> _warmUpParcelsCache() async {
    try {
      if (kDebugMode) debugPrint('[Parcels] precargando caché tras login...');
      final result = await sl<GetParcelsUseCase>()(const NoParams());
      if (kDebugMode) {
        result.fold(
          (failure) => debugPrint('[Parcels] precarga falló: ${failure.message}'),
          (parcels) => debugPrint(
            '[Parcels] precarga OK: ${parcels.length} parcela(s) -- '
            '${parcels.map((p) => '${p.seleccionId}:"${p.cropName}"->region="${p.region}"').join(', ')}',
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Parcels] Precarga de caché tras login falló: $e');
    }
  }

  Future<void> _onLoggedOut() async {
    if (!Platform.isAndroid) return;
    try {
      await sl<CancelAlertSubscriptionUseCase>()(const NoParams());
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Cancelación tras logout falló: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<AuthBloc>()..add(const AuthCheckSessionRequested()),
        ),
        BlocProvider(
          create: (_) => sl<HomeBloc>()..add(const HomeLoadRequested()),
        ),
        BlocProvider(create: (_) => sl<DiagnosisBloc>()),
        BlocProvider(
          create: (_) => sl<TreatmentBloc>()..add(const TreatmentAgendaRequested()),
        ),
        BlocProvider(
          create: (_) => sl<ParcelBloc>()..add(const ParcelLoadRequested()),
        ),
        BlocProvider(
          create: (_) => sl<OfflineCubit>()..loadStatus(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            _onLoggedIn();
          } else if (state is AuthUnauthenticated) {
            _onLoggedOut();
          }
        },
        child: MaterialApp(
          navigatorKey: AgroGraphApp.navigatorKey,
          title: 'AgroGraph-MAS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const SplashPage(),
        ),
      ),
    );
  }
}

// Shell principal con BottomNavigationBar de 5 tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Token disponible solo después del login — recarga con JWT válido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParcelBloc>().add(const ParcelLoadRequested());
    });
  }

  /// Cambia de tab con los mismos efectos secundarios que ya disparaba el
  /// BottomNavigationBar (reset de Diagnostico, refresco de Agenda). Se
  /// reutiliza tanto desde el tap en la barra como desde los enlaces
  /// "Ver agenda"/"Ver todos" del Inicio, para que ambos caminos se
  /// comporten exactamente igual.
  void _goToTab(int index) {
    final prev = _currentIndex;
    setState(() => _currentIndex = index);
    // Al volver al tab de cámara, limpia estados residuales
    if (index == 1 && prev != 1) {
      final bloc = context.read<DiagnosisBloc>();
      if (bloc.state is DiagnosisResult || bloc.state is DiagnosisError) {
        bloc.add(const DiagnosisReset());
      }
    }
    // Refresca la agenda desde Hive cada vez que se abre el tab
    if (index == 3) {
      context.read<TreatmentBloc>().add(const TreatmentAgendaRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(onNavigateToTab: _goToTab), // Tab 0: Inicio
          const DiagnosisPage(),  // Tab 1: Diagnostico
          const ParcelsPage(),    // Tab 2: Mis Parcelas
          const TreatmentPage(),  // Tab 3: Agenda
          const ProfilePage(),    // Tab 4: Perfil
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
          onTap: _goToTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surfaceContainerLowest,
          selectedItemColor: AppColors.navActive,
          unselectedItemColor: AppColors.navInactive,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              label: 'Diagnostico',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.landscape_outlined),
              label: 'Mis Parcelas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              label: 'Perfil',
            ),
          ],
        ),
    );
  }
}

// -- Pantallas auxiliares --

