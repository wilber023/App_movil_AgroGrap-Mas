// =============================================================================
// Feature: Auth -- Pantalla de Inicio de Sesión — Diseño Orgánico Premium
// =============================================================================
// Paleta: eucalipto apagado (#E6EFEB) → hueso almendra (#F9FBFA) → blanco
// Elementos: sin líneas marcadas — volumen por sombras difuminadas suaves
// Geometría: BorderRadius.circular(16) en todos los componentes interactivos
// Botón: terracota quemada #CB6E44, sombra cálida 30% opacidad
// Campos: contenedor sage white #F4F8F6 con sombra animada en foco
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/security/screen_security.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/profile_type.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/login_back_button.dart';
import '../widgets/login_brand_mark.dart';
import '../widgets/login_feedback.dart';
import '../widgets/login_misc_widgets.dart';
import '../widgets/login_role_switch.dart';
import '../widgets/login_toggle_eye_button.dart';
import 'register_page.dart';
import '../../../../../main.dart';
import '../../../../aprendiz/shell/aprendiz_main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // ── Lógica intacta ─────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    // MASVS-STORAGE: bloquea capturas de pantalla mientras se ingresan credenciales.
    ScreenSecurity.enable();
  }

  @override
  void dispose() {
    ScreenSecurity.disable();
    _usernameController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  ProfileType get _currentProfileType =>
      _tabController.index == 0
          ? ProfileType.agricultor
          : ProfileType.aprendizAgricola;

  // ── Build principal ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.lg, top: AppSpacing.sm),
          child: const LoginBackButton(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Degradado orgánico: eucalipto desaturado → hueso almendra → blanco
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.authBgTop,
              AppColors.authBgMid,
              AppColors.authBgBottom,
              AppColors.onPrimary,
            ],
            stops: [0.0, 0.25, 0.60, 1.0],
          ),
        ),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: _handleAuthState,
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xhugePlus),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xxlPlus),
                      const LoginBrandMark(),
                      const SizedBox(height: AppSpacing.xxhugePlus),
                      LoginRoleSwitch(
                        selectedIndex: _tabController.index,
                        onSelect: (index) => _tabController.animateTo(
                          index,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxhugePlus),
                      AuthTextField(
                        controller: _usernameController,
                        label: 'USUARIO',
                        hintText: 'Ej: wil_hdz',
                        prefixIcon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa tu usuario';
                          }
                          if (v.trim().length < 3) {
                            return 'Mínimo 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.huge),
                      AuthTextField(
                        controller: _passwordController,
                        label: 'CONTRASEÑA',
                        hintText: 'Ingresa tu contraseña',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        suffixIcon: LoginToggleEyeButton(
                          obscured: _obscurePassword,
                          onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const LoginForgotPasswordLink(),
                      const SizedBox(height: AppSpacing.giant),
                      LoginButton(
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _onLoginPressed,
                      ),
                      const SizedBox(height: AppSpacing.giantPlus),
                      const LoginDivider(),
                      const SizedBox(height: AppSpacing.xxhuge),
                      LoginRegisterLink(onTap: _goToRegister),
                      const SizedBox(height: AppSpacing.xgiantPlus),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Manejador BLoC (lógica intacta) ───────────────────────────────────────
  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      if (state.profileType == ProfileType.agricultor) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else if (state.profileType == ProfileType.aprendizAgricola) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AprendizMainShell()),
        );
      }
    } else if (state is AuthFeatureNotReady) {
      showLoginComingSoonDialog(context, state.profileType);
    } else if (state is AuthFailureState) {
      showLoginErrorToast(context, state.message);
    }
  }

  void _goToRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => GetIt.instance<AuthBloc>(),
          child: RegisterPage(profileType: _currentProfileType),
        ),
      ),
    );
  }

  // ── Lógica de negocio (intacta) ────────────────────────────────────────────
  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthLoginRequested(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            profileType: _currentProfileType,
          ));
    }
  }
}
