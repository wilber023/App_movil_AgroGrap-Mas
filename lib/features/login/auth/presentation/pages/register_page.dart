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
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/profile_type.dart';
import '../../domain/usecases/validate_register_form_usecase.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/register_feedback.dart';
import '../widgets/register_form_field.dart';
import '../widgets/register_header.dart';
import '../widgets/register_links.dart';
import '../widgets/register_profile_banner.dart';
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
                  const RegisterHeader(),
                  const SizedBox(height: AppSpacing.xxhuge),
                  RegisterProfileBanner(profileType: _currentProfileType),
                  const SizedBox(height: AppSpacing.xxhuge),

                  // -- Formulario --
                  RegisterFormField(
                    controller: _firstNameController,
                    label: 'Nombre',
                    hintText: 'Ej: Wilber',
                    prefixIcon: Icons.badge_outlined,
                    errorText: _validationErrors['firstName'],
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.huge),

                  RegisterFormField(
                    controller: _lastNameController,
                    label: 'Apellido',
                    hintText: 'Ej: Hernandez',
                    prefixIcon: Icons.person_outline_rounded,
                    errorText: _validationErrors['lastName'],
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.huge),

                  RegisterFormField(
                    controller: _usernameController,
                    label: 'Usuario',
                    hintText: 'Ej: wil_hdz',
                    prefixIcon: Icons.alternate_email_rounded,
                    errorText: _validationErrors['username'],
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.huge),

                  RegisterFormField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    hintText: 'Mínimo 8 caracteres, con mayúscula, número y símbolo',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    errorText: _validationErrors['password'],
                    onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.huge),

                  RegisterFormField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar contraseña',
                    hintText: 'Repite tu contraseña',
                    prefixIcon: Icons.lock_outline_rounded,
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

                  RegisterCrossProfileLink(
                    profileType: _currentProfileType,
                    onSwitch: () {
                      setState(() {
                        _currentProfileType = _currentProfileType == ProfileType.agricultor
                            ? ProfileType.aprendizAgricola
                            : ProfileType.agricultor;
                        _validationErrors.clear();
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xhuge),

                  const RegisterDivider(),
                  const SizedBox(height: AppSpacing.xhuge),

                  RegisterLoginLink(onTap: _goToLogin),
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
      showRegisterSuccessToast(context, state.fullName);
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
      showRegisterComingSoonDialog(context, state.profileType);
    } else if (state is AuthFailureState) {
      showRegisterErrorToast(context, state.message);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => GetIt.instance<AuthBloc>(),
          child: const LoginPage(),
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
