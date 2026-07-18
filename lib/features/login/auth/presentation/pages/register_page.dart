// =============================================================================
// Feature: Auth -- Pantalla de Registro (Unificada)
// =============================================================================
// Capa: Presentation / Pages
// Registro parametrizado para Agricultor y Aprendiz Agricola.
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
import '../../domain/usecases/validate_register_form_usecase.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_text_field.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  final ProfileType profileType;

  const RegisterPage({super.key, required this.profileType});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late ProfileType _currentProfileType;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  Map<String, String> _validationErrors = {};

  @override
  void initState() {
    super.initState();
    _currentProfileType = widget.profileType;
    // MASVS-STORAGE: bloquea capturas de pantalla mientras se crea la contraseña.
    ScreenSecurity.enable();
  }

  @override
  void dispose() {
    ScreenSecurity.disable();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDs2,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: _handleAuthStateChange,
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xhuge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.xxhuge),
                  _buildProfileBanner(),
                  const SizedBox(height: AppSpacing.xxhuge),
                  
                  // -- Formulario --
                  _buildTextField(
                    controller: _firstNameController,
                    label: 'Nombre',
                    hintText: 'Ej: Wilber',
                    prefixIcon: Icons.badge_outlined,
                    errorText: _validationErrors['firstName'],
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.huge),

                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Apellido',
                    hintText: 'Ej: Hernandez',
                    prefixIcon: Icons.person_outline_rounded,
                    errorText: _validationErrors['lastName'],
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.huge),

                  _buildTextField(
                    controller: _usernameController,
                    label: 'Usuario',
                    hintText: 'Ej: wil_hdz',
                    prefixIcon: Icons.alternate_email_rounded,
                    errorText: _validationErrors['username'],
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.huge),

                  _buildPasswordField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    hintText: 'Mínimo 8 caracteres, con mayúscula, número y símbolo',
                    obscureText: _obscurePassword,
                    errorText: _validationErrors['password'],
                    onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.huge),

                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar contraseña',
                    hintText: 'Repite tu contraseña',
                    obscureText: _obscureConfirmPassword,
                    errorText: _validationErrors['confirmPassword'],
                    onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.giant),

                  AuthPrimaryButton(
                    text: 'Crear cuenta',
                    icon: Icons.person_add_alt_1_rounded,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _onRegisterPressed,
                  ),
                  const SizedBox(height: AppSpacing.xhuge),

                  _buildCrossProfileLink(),
                  const SizedBox(height: AppSpacing.xhuge),
                  
                  _buildDivider(),
                  const SizedBox(height: AppSpacing.xhuge),
                  
                  _buildLoginLink(),
                  const SizedBox(height: AppSpacing.giant),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleAuthStateChange(BuildContext context, AuthState state) {
    if (state is AuthRegistrationSuccess) {
      _showSuccessToast(context, state.fullName);
      // Redirigir al Login tras un breve instante visible del toast.
      // Se usa pushAndRemoveUntil para limpiar el stack de navegación.
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider(
              create: (_) => GetIt.instance<AuthBloc>(),
              child: const LoginPage(),
            ),
          ),
          (route) => false, // elimina todo el stack anterior
        );
      });
    } else if (state is AuthFeatureNotReady) {
      _showComingSoonDialog(context, state.profileType);
    } else if (state is AuthFailureState) {
      _showErrorToast(context, state.message);
    }
  }

  void _showSuccessToast(BuildContext context, String fullName) {
    final firstName = fullName.split(' ').first;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.onPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '¡Bienvenido, $firstName!',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Cuenta creada exitosamente.',
                      style: AppTypography.etiquetaSm.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxlPlus,
            vertical: AppSpacing.xl,
          ),
          duration: const Duration(seconds: 3),
          elevation: 6,
        ),
      );
  }

  void _showErrorToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.onPrimary, size: 22),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.labelMd.copyWith(color: AppColors.onPrimary),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxlPlus,
            vertical: AppSpacing.xl,
          ),
          duration: const Duration(seconds: 4),
          elevation: 6,
        ),
      );
  }

  void _showComingSoonDialog(BuildContext context, ProfileType profileType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xlPlus)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.warmAmber),
            const SizedBox(width: AppSpacing.md),
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
            onPressed: () {
               Navigator.of(ctx).pop();
            },
            child: Text(
              'Entendido',
              style: AppTypography.labelMd.copyWith(color: AppColors.forestGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: AppColors.forestGreen,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.huge),
        Text(
          'Crea tu cuenta',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.authHeaderTitle,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tus datos se guardan de forma segura localmente.',
          style: AppTypography.etiquetaSm.copyWith(
            color: AppColors.authMutedSage,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileBanner() {
    final isAgricultor = _currentProfileType == ProfileType.agricultor;
    final color = isAgricultor ? AppColors.authAgricultorAccent : AppColors.warmAmber;
    final icon = isAgricultor ? Icons.agriculture_outlined : Icons.spa_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxlPlus,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lgXl),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Text(
              'Registrando como: ${_currentProfileType.displayName}',
              style: AppTypography.labelMd.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    String? errorText,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTextField(
          controller: controller,
          label: label,
          hintText: hintText,
          prefixIcon: prefixIcon,
          textInputAction: textInputAction,
          validator: (_) => null, // Validation done manually
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xxlPlus),
            child: Text(
              errorText,
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    String? errorText,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTextField(
          controller: controller,
          label: label,
          hintText: hintText,
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: obscureText,
          textInputAction: textInputAction,
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.authMutedSage,
              size: 22,
            ),
            onPressed: onToggleObscure,
          ),
          validator: (_) => null, // Validation done manually
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xxlPlus),
            child: Text(
              errorText,
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _buildCrossProfileLink() {
    final isAgricultor = _currentProfileType == ProfileType.agricultor;
    final otherProfile = isAgricultor ? ProfileType.aprendizAgricola : ProfileType.agricultor;
    final text1 = isAgricultor ? '¿Eres un principiante? ' : '¿Ya tienes experiencia? ';
    final text2 = isAgricultor ? 'Cambiar a Aprendiz Agrícola' : 'Cambiar a Agricultor';
    
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentProfileType = otherProfile;
            _validationErrors.clear();
          });
        },
        child: RichText(
          text: TextSpan(
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.authMutedSage,
              fontSize: 13,
            ),
            children: [
              TextSpan(text: text1),
              TextSpan(
                text: text2,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.forestGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 0.5, color: AppColors.cardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
          child: Text(
            'o',
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.authMutedSage),
          ),
        ),
        Expanded(child: Container(height: 0.5, color: AppColors.cardBorder)),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider(
                create: (_) => GetIt.instance<AuthBloc>(),
                child: const LoginPage(),
              ),
            ),
          );
        },
        child: RichText(
          text: TextSpan(
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.authMutedSage,
              fontSize: 13,
            ),
            children: [
              const TextSpan(text: '¿Ya tienes cuenta? '),
              TextSpan(
                text: 'Iniciar sesión',
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
    );
  }

  void _onRegisterPressed() {
    // 1. Validar usando el UseCase
    final formData = RegisterFormData(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    final validateUseCase = GetIt.instance<ValidateRegisterFormUseCase>();
    final validation = validateUseCase(formData);

    if (validation.isValid) {
      setState(() => _validationErrors.clear());
      
      // 2. Enviar evento al BLoC
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          fullName: formData.fullName,
          username: formData.username,
          password: formData.password,
          profileType: _currentProfileType,
        ),
      );
    } else {
      setState(() {
        _validationErrors = validation.errors;
      });
    }
  }
}
