// =============================================================================
// Feature: Auth -- Pantalla Splash
// =============================================================================
// Capa: Presentation / Pages
// Fondo verde oscuro #1B5E20 full screen, sin gradiente, sin chips, sin botones.
// Es una pantalla 100% automatica, sin interaccion.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../bloc/splash_cubit.dart';
import 'select_profile_page.dart';
import '../../../../main.dart';
import '../../../aprendiz/presentation/pages/aprendiz_main_shell.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late SplashCubit _splashCubit;

  @override
  void initState() {
    super.initState();
    _splashCubit = GetIt.instance<SplashCubit>();
    _splashCubit.checkSession();
  }

  @override
  void dispose() {
    _splashCubit.close();
    super.dispose();
  }

  void _handleSplashState(BuildContext context, SplashState state) {
    if (state is SplashNavigateToAgricultorHome) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else if (state is SplashNavigateToProfileSelect) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SelectProfilePage()),
      );
    } else if (state is SplashNavigateToAprendizHome) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AprendizMainShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _splashCubit,
      child: BlocListener<SplashCubit, SplashState>(
        listener: _handleSplashState,
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF1B5E20),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  // Icono central (hoja)
                  const Icon(
                    Icons.eco_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  // Titulo
                  const Text(
                    'AgroGraph-MAS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Subtitulo
                  const Text(
                    'Tu agrónomo en el bolsillo',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF81C784), // Light green to match image
                    ),
                  ),
                  const Spacer(flex: 3),
                  // Barra de progreso indeterminada en la parte inferior
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 80),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: Color(0xFF2E7D32),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
