import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/diagnosis/presentation/bloc/diagnosis_bloc.dart';
import 'features/diagnosis/presentation/pages/diagnosis_page.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/parcels/presentation/pages/parcels_page.dart';
import 'features/parcels/presentation/bloc/parcel_bloc.dart';
import 'features/treatment/presentation/bloc/treatment_bloc.dart';
import 'features/treatment/presentation/pages/treatment_page.dart';

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

class AgroGraphApp extends StatelessWidget {
  const AgroGraphApp({super.key});

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
      ],
      child: MaterialApp(
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomePage(),       // Tab 0: Inicio
          DiagnosisPage(),  // Tab 1: Diagnostico
          ParcelsPage(),    // Tab 2: Mis Parcelas
          TreatmentPage(),  // Tab 3: Agenda
          ProfilePage(),    // Tab 4: Perfil
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
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

