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
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/profile_type.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_text_field.dart';
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
          child: _BackButton(),
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
                      _buildBrandMark(),
                      const SizedBox(height: AppSpacing.xxhugePlus),
                      _buildRoleSwitch(),
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
                        suffixIcon: _ToggleEyeButton(
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
                      _buildForgotPassword(),
                      const SizedBox(height: AppSpacing.giant),
                      _buildLoginButton(isLoading),
                      const SizedBox(height: AppSpacing.giantPlus),
                      _buildDivider(),
                      const SizedBox(height: AppSpacing.xxhuge),
                      _buildRegisterLink(),
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
      _showComingSoon(context, state.profileType);
    } else if (state is AuthFailureState) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.onPrimary, size: 20),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(state.message,
                    style: AppTypography.labelMd.copyWith(
                        color: AppColors.onPrimary, fontSize: 13)),
              ),
            ]),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl)),
            margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.xl),
            duration: const Duration(seconds: 4),
            elevation: 0,
          ),
        );
    }
  }

  void _showComingSoon(BuildContext context, ProfileType profileType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.authBgBottom,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxlPlus)),
        title: Row(children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warmAmber),
          const SizedBox(width: AppSpacing.md),
          Text('Próximamente',
              style: AppTypography.headlineMd.copyWith(fontSize: 18)),
        ]),
        content: Text(
          'El perfil ${profileType.displayName} estará disponible muy pronto.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.authInkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Entendido',
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.forestGreen)),
          ),
        ],
      ),
    );
  }

  // ── Widgets visuales ───────────────────────────────────────────────────────

  /// Ícono de marca + títulos. El contenedor usa rounded rectangle (16px)
  /// en lugar de círculo para un lenguaje geométrico más arquitectónico.
  Widget _buildBrandMark() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícono: rectángulo redondeado 16px — no píldora circular
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.forestGreen, AppColors.authBrandGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xlPlus),
            boxShadow: [
              BoxShadow(
                color: AppColors.forestGreen.withValues(alpha: 0.30),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.eco_rounded, color: AppColors.onPrimary, size: 26),
        ),
        const SizedBox(height: AppSpacing.xhugePlus),
        Text(
          'Inicia sesión',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.authFieldText,
            fontSize: 27,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.smMd),
        Text(
          'Accede a tus parcelas, diagnósticos y agenda.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.authInkMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// Selector de rol rediseñado: "Tab Switch" integrado.
  /// El contenedor se fusiona con el fondo superior del degradado.
  /// Seleccionado = relieve blanco almendra suave + micro-sombra.
  /// No seleccionado = transparente, solo tipografía.
  Widget _buildRoleSwitch() {
    final selected = _tabController.index;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        // Color que se funde con el degradado eucalipto del fondo
        color: AppColors.authRoleSwitchBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          _buildRoleTab('Agricultor', 0, selected),
          const SizedBox(width: AppSpacing.xs),
          _buildRoleTab('Aprendiz', 1, selected),
        ],
      ),
    );
  }

  Widget _buildRoleTab(String label, int index, int selected) {
    final isSelected = index == selected;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tabController.animateTo(index,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lgXl),
          decoration: BoxDecoration(
            // Seleccionado: hueso almendra = mismo tono del fondo inferior
            color: isSelected ? AppColors.authBgBottom : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.authFieldText.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelMd.copyWith(
              color: isSelected ? AppColors.authFieldText : AppColors.authInkMuted,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  /// Link plano sin TextButton ni contenedor — texto oscuro, sin decoración
  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text(
            '¿Olvidaste tu contraseña?',
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.authInkMuted,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  /// Botón terracota con sombra cálida — el calor visual del CTA
  /// contrasta suavemente con el fondo verde-neutro de la pantalla.
  Widget _buildLoginButton(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        boxShadow: isLoading
            ? []
            : [
                BoxShadow(
                  color: AppColors.authTerracota.withValues(alpha: 0.30),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: AuthPrimaryButton(
        text: 'Iniciar sesión',
        icon: Icons.login_rounded,
        isLoading: isLoading,
        onPressed: isLoading ? null : _onLoginPressed,
      ),
    );
  }

  /// Divisor orgánico — sin contendor para el "o", solo tipografía flotante
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.authDivider,
            thickness: 0.7,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
          child: Text(
            'o',
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.authInkMuted,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.authDivider,
            thickness: 0.7,
          ),
        ),
      ],
    );
  }

  /// Link de registro — texto plano, perfectamente alineado a la rejilla
  Widget _buildRegisterLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider(
              create: (_) => GetIt.instance<AuthBloc>(),
              child: RegisterPage(profileType: _currentProfileType),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: RichText(
            text: TextSpan(
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.authInkMuted,
                fontSize: 13,
              ),
              children: [
                const TextSpan(text: '¿No tienes cuenta?  '),
                TextSpan(
                  text: 'Crear cuenta',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.forestGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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

// ── Widgets privados auxiliares ───────────────────────────────────────────────

/// Botón de retroceso circular translúcido — convención de navegación móvil
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.75),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_rounded,
            color: AppColors.onSurface, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// Botón ojo para mostrar/ocultar contraseña — icono trazo fino, gris piedra
class _ToggleEyeButton extends StatelessWidget {
  final bool obscured;
  final VoidCallback onTap;

  const _ToggleEyeButton({required this.obscured, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.authFieldIcon,
        size: 20,
      ),
      onPressed: onTap,
    );
  }
}
