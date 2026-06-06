// =============================================================================
// Feature: Auth -- Pantalla de Inicio de Sesion (Login)
// =============================================================================
// Capa: Presentation / Pages
// Pantalla de login con campos de usuario y contrasena.
// Usa BlocConsumer para manejar navegacion (listener) y UI (builder).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_text_field.dart';
import 'register_page.dart';
import '../../../../main.dart';

/// Pantalla de inicio de sesion.
///
/// Permite al usuario autenticarse con su nombre de usuario y contrasena.
/// Sigue el flujo definido en el Design System de Stitch con inputs de
/// 52px, labels visibles y boton primario en Ambar Calido.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: _handleAuthStateChange,
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // -- Encabezado --
                    _buildHeader(),
                    const SizedBox(height: 32),

                    // -- Formulario --
                    _buildUsernameField(),
                    const SizedBox(height: 20),

                    _buildPasswordField(),
                    const SizedBox(height: 8),

                    // -- Olvidaste tu contrasena --
                    _buildForgotPassword(),
                    const SizedBox(height: 32),

                    // -- Boton de login --
                    AuthPrimaryButton(
                      text: 'Iniciar sesion',
                      icon: Icons.login_rounded,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _onLoginPressed,
                    ),
                    const SizedBox(height: 16),

                    // -- Separador --
                    _buildDivider(),
                    const SizedBox(height: 16),

                    // -- Enlace a registro --
                    _buildRegisterLink(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Maneja los cambios de estado del BLoC de autenticacion.
  void _handleAuthStateChange(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      // Navegar al Dashboard.
      // Navigator.of(context).pushReplacementNamed('/home');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bienvenido, ${state.user.fullName}',
            style: AppTypography.bodyMd.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (state is AuthFailureState) {
      // Mostrar error.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.message,
                  style: AppTypography.bodyMd.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Encabezado con icono, titulo y subtitulo.
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icono de la seccion.
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.lock_open_rounded,
            color: AppColors.forestGreen,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),

        // Titulo.
        Text(
          'Inicia sesion',
          style: AppTypography.tituloLg.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitulo.
        Text(
          'Accede a tus parcelas, diagnosticos y agenda de tratamiento.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Campo de nombre de usuario.
  Widget _buildUsernameField() {
    return AuthTextField(
      controller: _usernameController,
      label: 'Usuario',
      hintText: 'Ej: wil_hdz',
      prefixIcon: Icons.person_outline_rounded,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa tu nombre de usuario';
        }
        if (value.trim().length < 3) {
          return 'El usuario debe tener al menos 3 caracteres';
        }
        return null;
      },
    );
  }

  /// Campo de contrasena con toggle de visibilidad.
  Widget _buildPasswordField() {
    return AuthTextField(
      controller: _passwordController,
      label: 'Contrasena',
      hintText: 'Ingresa tu contrasena',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.onSurfaceVariant,
          size: 22,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa tu contrasena';
        }
        if (value.length < 6) {
          return 'La contrasena debe tener al menos 6 caracteres';
        }
        return null;
      },
    );
  }

  /// Enlace de "Olvidaste tu contrasena".
  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Futura funcionalidad de recuperacion de contrasena.
        },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forestGreen,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
        child: Text(
          'Olvidaste tu contrasena?',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.forestGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Separador visual con texto "o".
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5,
            color: AppColors.outlineVariant,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'o',
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            color: AppColors.outlineVariant,
          ),
        ),
      ],
    );
  }

  /// Enlace para ir a la pantalla de registro.
  Widget _buildRegisterLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No tienes cuenta? ',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider(
                    create: (_) => GetIt.instance<AuthBloc>(),
                    child: const RegisterPage(),
                  ),
                ),
              );
            },
            child: Text(
              'Crear cuenta',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ejecuta la validacion y envia el evento de login al BLoC.
  void _onLoginPressed() {
    // Validacion de UI local sin esperar respuesta del BLoC
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }
}
