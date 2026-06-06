// =============================================================================
// Feature: Auth -- Pantalla de Bienvenida (Welcome / Splash)
// =============================================================================
// Capa: Presentation / Pages
// Mapeada desde: Stitch screen "Bienvenida - AgroGraph-MAS"
//   Screen ID: 6a020f4028fb4b24af0ab7f78cdd13e1
//
// Estructura visual (segun Stitch):
//   - Fondo con degradado suave verde
//   - Icono central de la app (hoja/planta)
//   - Titulo "AgroGraph-MAS"
//   - Subtitulo "Tu agronomo en el bolsillo"
//   - Boton primario "Crear cuenta" (Ambar Calido)
//   - Boton secundario "Iniciar sesion" (Outlined Forest Green)
//   - Texto inferior con version
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_buttons.dart';
import 'login_page.dart';
import 'register_page.dart';

/// Pantalla de bienvenida de la aplicacion.
///
/// Es la primera pantalla que ve el usuario si no hay sesion activa.
/// Muestra el branding de AgroGraph-MAS y los accesos a registro e inicio
/// de sesion.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Navegar al Dashboard cuando la sesion esta activa.
          // Navigator.of(context).pushReplacementNamed('/home');
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryContainer,
                AppColors.primary,
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // -- Seccion superior: espaciador --
                      SizedBox(height: screenHeight * 0.08),

                      // -- Seccion central: branding --
                      _buildBrandingSection(),

                      // -- Seccion inferior: acciones --
                      _buildActionsSection(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Seccion central con el icono, titulo y subtitulo de la app.
  Widget _buildBrandingSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icono de la aplicacion.
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.eco_rounded,
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),

        // Titulo principal de la app.
        Text(
          'AgroGraph-MAS',
          style: AppTypography.tituloLg.copyWith(
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Subtitulo descriptivo.
        Text(
          'Tu agronomo en el bolsillo',
          style: AppTypography.bodyLg.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Indicadores de funcionalidad.
        _buildFeatureChips(),
      ],
    );
  }

  /// Chips de funcionalidades principales.
  Widget _buildFeatureChips() {
    final features = [
      (Icons.camera_alt_outlined, 'Diagnostico IA'),
      (Icons.cloud_off_outlined, 'Modo Offline'),
      (Icons.landscape_outlined, 'Gestion de Parcelas'),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: features.map((feature) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                feature.$1,
                size: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Text(
                feature.$2,
                style: AppTypography.etiquetaSm.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Seccion inferior con botones de accion y version.
  Widget _buildActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 48),

          // Boton primario: Crear cuenta.
          AuthPrimaryButton(
            text: 'Crear cuenta',
            icon: Icons.person_add_alt_1_outlined,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider(
                    create: (_) => GetIt.instance<AuthBloc>(),
                    child: const RegisterPage(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Boton secundario: Iniciar sesion.
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider(
                      create: (_) => GetIt.instance<AuthBloc>(),
                      child: const LoginPage(),
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Iniciar sesion',
                    style: AppTypography.labelMd.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Version de la aplicacion.
          Text(
            'v1.0.0 - Modo Offline-First',
            style: AppTypography.etiquetaSm.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}


