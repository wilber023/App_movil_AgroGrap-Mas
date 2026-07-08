import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/injection_container.dart';
import 'core/session/session_manager.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/login/auth/presentation/bloc/auth_bloc.dart';
import 'features/login/auth/presentation/bloc/auth_event.dart';
import 'features/login/auth/presentation/pages/select_profile_page.dart';
import 'features/login/auth/presentation/pages/splash_page.dart';
import 'features/agricultor/diagnosis/presentation/bloc/diagnosis_bloc.dart';
import 'features/agricultor/diagnosis/presentation/pages/diagnosis_page.dart';
import 'features/agricultor/home/presentation/bloc/home_bloc.dart';
import 'features/agricultor/home/presentation/pages/home_page.dart';
import 'features/agricultor/profile/presentation/pages/profile_page.dart';
import 'features/agricultor/parcels/presentation/pages/parcels_page.dart';
import 'features/agricultor/parcels/presentation/bloc/parcel_bloc.dart';
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
      child: MaterialApp(
        navigatorKey: AgroGraphApp.navigatorKey,
        title: 'AgroGraph-MAS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashPage(),
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

