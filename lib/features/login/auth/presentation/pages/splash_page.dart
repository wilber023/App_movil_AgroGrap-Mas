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

import '../../../../../core/security/force_update_gate.dart';
import '../../../../../core/security/root_detection.dart';
import '../bloc/splash_cubit.dart';
import 'select_profile_page.dart';
import '../../../../../main.dart';
import '../../../../aprendiz/presentation/pages/aprendiz_main_shell.dart';

/// Versión instalada (pubspec.yaml `version:`). Ver [ForceUpdateGate].
const String _kAppVersion = '1.0.0+1';

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

  Future<void> _handleSplashState(BuildContext context, SplashState state) async {
    // MASVS-CODE: mecanismo de actualización forzada. `minSupportedVersion`
    // hoy es igual a la versión actual (no hay endpoint de backend aún),
    // por lo que esto nunca bloquea todavía — ver ForceUpdateGate.
    if (ForceUpdateGate.needsUpdate(_kAppVersion) && context.mounted) {
      await _showForceUpdateDialog(context);
      return;
    }

    // MASVS-RESILIENCE: advertencia (no bloqueo) si el dispositivo está
    // rooteado/con jailbreak — AgroGraph maneja datos económicos y
    // agronómicos sensibles del productor.
    await _warnIfCompromisedDevice(context);
    if (!context.mounted) return;

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

  Future<void> _showForceUpdateDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Actualización requerida'),
        content: const Text(
          'Hay una nueva versión de AgroGraph disponible. Actualiza para '
          'continuar usando la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  bool _rootWarningShown = false;

  Future<void> _warnIfCompromisedDevice(BuildContext context) async {
    if (_rootWarningShown) return;
    final compromised = await RootDetection.isCompromised();
    if (!context.mounted || !compromised) return;
    _rootWarningShown = true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispositivo no confiable'),
        content: const Text(
          'Detectamos que este dispositivo está rooteado o con jailbreak. '
          'Usar AgroGraph en este estado puede exponer tus datos agronómicos '
          'y económicos a otras apps. Continúa bajo tu propio riesgo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido, continuar'),
          ),
        ],
      ),
    );
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
