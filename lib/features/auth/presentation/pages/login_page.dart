// =============================================================================
// Feature: Auth -- Pantalla de Inicio de Sesion Dinamica
// =============================================================================
// Capa: Presentation / Pages
// Login Dinamico (tabs Agricultor / Aprendiz Agricola).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/profile_type.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_text_field.dart';
import 'register_page.dart';
import '../../../../main.dart';
import '../../../aprendiz/presentation/pages/aprendiz_main_shell.dart';

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
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  ProfileType get _currentProfileType =>
      _tabController.index == 0
          ? ProfileType.agricultor
          : ProfileType.aprendizAgricola;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
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
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFBCE8D2),
              Color(0xFFDCF3E8),
              Color(0xFFF4FBF7),
              Colors.white,
            ],
            stops: [0.0, 0.18, 0.45, 1.0],
          ),
        ),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: _handleAuthStateChange,
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildTabs(),
                      const SizedBox(height: 28),
                      _buildUsernameField(),
                      const SizedBox(height: 18),
                      _buildPasswordField(),
                      const SizedBox(height: 6),
                      _buildForgotPassword(),
                      const SizedBox(height: 28),
                      _buildLoginButton(isLoading),
                      const SizedBox(height: 28),
                      _buildDivider(),
                      const SizedBox(height: 24),
                      _buildRegisterLink(),
                      const SizedBox(height: 40),
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

  // ── Manejador de estados BLoC (sin cambios) ────────────────────────────────
  void _handleAuthStateChange(BuildContext context, AuthState state) {
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
      _showComingSoonDialog(context, state.profileType);
    } else if (state is AuthFailureState) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.message,
                    style:
                        AppTypography.labelMd.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: const Duration(seconds: 4),
            elevation: 6,
          ),
        );
    }
  }

  void _showComingSoonDialog(BuildContext context, ProfileType profileType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: AppColors.warmAmber),
            const SizedBox(width: 8),
            Text(
              'Próximamente',
              style: AppTypography.headlineMd.copyWith(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'El perfil ${profileType.displayName} estará disponible muy pronto. Estamos preparando tu experiencia guiada.',
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Entendido',
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.forestGreen),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets visuales ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícono con gradiente y sombra verde
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.forestGreen, Color(0xFF1B5E3B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.forestGreen.withValues(alpha: 0.38),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 22),
        Text(
          'Inicia sesión',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Accede a tus parcelas, diagnósticos y agenda.',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.forestGreen.withValues(alpha: 0.13),
              AppColors.primary.withValues(alpha: 0.07),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.forestGreen.withValues(alpha: 0.22),
            width: 1.5,
          ),
        ),
        labelColor: AppColors.forestGreen,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        labelStyle:
            AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            AppTypography.labelMd.copyWith(fontWeight: FontWeight.w400),
        tabs: const [
          Tab(text: 'Agricultor'),
          Tab(text: 'Aprendiz'),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return _FieldShadowWrap(
      child: AuthTextField(
        controller: _usernameController,
        label: 'Usuario',
        hintText: 'Ej: wil_hdz',
        prefixIcon: Icons.person_outline_rounded,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Ingresa tu usuario';
          if (value.trim().length < 3) return 'Debe tener al menos 3 caracteres';
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return _FieldShadowWrap(
      child: AuthTextField(
        controller: _passwordController,
        label: 'Contraseña',
        hintText: 'Ingresa tu contraseña',
        prefixIcon: Icons.lock_outline_rounded,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF6B8F71),
            size: 22,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
          if (value.length < 6) return 'Mínimo 6 caracteres';
          return null;
        },
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forestGreen,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          '¿Olvidaste tu contraseña?',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.forestGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmAmber.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 7),
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.outlineVariant.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Text(
              'o',
              style: AppTypography.etiquetaSm.copyWith(
                  color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.outlineVariant.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider(
                create: (_) => GetIt.instance<AuthBloc>(),
                child: RegisterPage(profileType: _currentProfileType),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: RichText(
            text: TextSpan(
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
              children: [
                const TextSpan(text: '¿No tienes cuenta?  '),
                TextSpan(
                  text: 'Crear cuenta →',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.forestGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Lógica de negocio (sin cambios) ───────────────────────────────────────
  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
              profileType: _currentProfileType,
            ),
          );
    }
  }
}

// Wrapper de sombra suave para cada campo de texto
class _FieldShadowWrap extends StatelessWidget {
  final Widget child;
  const _FieldShadowWrap({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
