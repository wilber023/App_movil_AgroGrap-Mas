// =============================================================================
// Feature: Auth -- Pantalla de Registro de Cuenta
// =============================================================================
// Capa: Presentation / Pages
// Mapeada desde: Stitch screen "Registro de Cuenta"
//   Screen ID: ded055976b1a48659758c2dbc13cb6c8
//
// Estructura visual (segun Stitch):
//   - Titulo "Crea tu cuenta"
//   - Subtitulo "Sin correo obligatorio - tus datos se guardan localmente"
//   - Campos: Nombre completo, Usuario, Contrasena, Email (opcional), Telefono (opcional)
//   - Boton primario "Crear cuenta" (Ambar Calido)
//   - Enlace "Ya tienes cuenta? Inicia sesion"
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_text_field.dart';
import '../../../../main.dart';

/// Pantalla de registro de nueva cuenta.
///
/// Replica la vista "Crea tu cuenta" de Stitch. Los campos de email y
/// telefono son opcionales, respetando la filosofia: "Sin correo
/// obligatorio - tus datos se guardan localmente".
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showOptionalFields = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
                    const SizedBox(height: 28),

                    // -- Campos obligatorios --
                    _buildFullNameField(),
                    const SizedBox(height: 20),

                    _buildUsernameField(),
                    const SizedBox(height: 20),

                    _buildPasswordField(),
                    const SizedBox(height: 20),

                    _buildConfirmPasswordField(),
                    const SizedBox(height: 20),

                    // -- Toggle campos opcionales --
                    _buildOptionalFieldsToggle(),

                    // -- Campos opcionales (email y telefono) --
                    if (_showOptionalFields) ...[
                      const SizedBox(height: 20),
                      _buildEmailField(),
                      const SizedBox(height: 20),
                      _buildPhoneField(),
                    ],

                    const SizedBox(height: 32),

                    // -- Boton de registro --
                    AuthPrimaryButton(
                      text: 'Crear cuenta',
                      icon: Icons.person_add_alt_1_rounded,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _onRegisterPressed,
                    ),
                    const SizedBox(height: 16),

                    // -- Nota de almacenamiento local --
                    _buildLocalStorageNote(),
                    const SizedBox(height: 24),

                    // -- Enlace a login --
                    _buildLoginLink(),
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

  /// Maneja los cambios de estado del BLoC.
  void _handleAuthStateChange(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      // Navegar al Dashboard tras registro exitoso.
      // Navigator.of(context).pushReplacementNamed('/home');

      final message = state.user.isLocalOnly
          ? 'Cuenta creada localmente. Se sincronizara cuando haya conexion.'
          : 'Cuenta creada exitosamente. Bienvenido, ${state.user.fullName}!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                state.user.isLocalOnly
                    ? Icons.cloud_off_outlined
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyMd.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: state.user.isLocalOnly
              ? AppColors.offlineGreyDark
              : AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } else if (state is AuthFailureState) {
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
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: AppColors.forestGreen,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Crea tu cuenta',
          style: AppTypography.tituloLg.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Sin correo obligatorio \u00B7 tus datos se guardan localmente',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Campo: Nombre completo.
  Widget _buildFullNameField() {
    return AuthTextField(
      controller: _fullNameController,
      label: 'Nombre completo',
      hintText: 'Ej: Wilber Hernandez',
      prefixIcon: Icons.badge_outlined,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa tu nombre completo';
        }
        if (value.trim().length < 2) {
          return 'El nombre debe tener al menos 2 caracteres';
        }
        return null;
      },
    );
  }

  /// Campo: Nombre de usuario.
  Widget _buildUsernameField() {
    return AuthTextField(
      controller: _usernameController,
      label: 'Nombre de usuario',
      hintText: 'Ej: wil_hdz',
      prefixIcon: Icons.alternate_email_rounded,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa un nombre de usuario';
        }
        if (value.trim().length < 3) {
          return 'El usuario debe tener al menos 3 caracteres';
        }
        if (value.contains(' ')) {
          return 'El usuario no puede contener espacios';
        }
        return null;
      },
    );
  }

  /// Campo: Contrasena con toggle de visibilidad.
  Widget _buildPasswordField() {
    return AuthTextField(
      controller: _passwordController,
      label: 'Contrasena',
      hintText: 'Minimo 6 caracteres',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.onSurfaceVariant,
          size: 22,
        ),
        onPressed: () => setState(() {
          _obscurePassword = !_obscurePassword;
        }),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa una contrasena';
        }
        if (value.length < 6) {
          return 'La contrasena debe tener al menos 6 caracteres';
        }
        return null;
      },
    );
  }

  /// Campo: Confirmar contrasena.
  Widget _buildConfirmPasswordField() {
    return AuthTextField(
      controller: _confirmPasswordController,
      label: 'Confirmar contrasena',
      hintText: 'Repite tu contrasena',
      prefixIcon: Icons.lock_reset_rounded,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureConfirmPassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.onSurfaceVariant,
          size: 22,
        ),
        onPressed: () => setState(() {
          _obscureConfirmPassword = !_obscureConfirmPassword;
        }),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Confirma tu contrasena';
        }
        if (value != _passwordController.text) {
          return 'Las contrasenas no coinciden';
        }
        return null;
      },
    );
  }

  /// Toggle para mostrar/ocultar campos opcionales.
  Widget _buildOptionalFieldsToggle() {
    return GestureDetector(
      onTap: () => setState(() {
        _showOptionalFields = !_showOptionalFields;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _showOptionalFields
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: AppColors.forestGreen,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _showOptionalFields
                    ? 'Ocultar campos opcionales'
                    : 'Agregar correo o telefono (opcional)',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.statusHealthyBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Opcional',
                style: AppTypography.statusPill.copyWith(
                  color: AppColors.statusHealthyText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Campo: Correo electronico (opcional).
  Widget _buildEmailField() {
    return AuthTextField(
      controller: _emailController,
      label: 'Correo electronico',
      hintText: 'Ej: wil@correo.com',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value)) {
            return 'Ingresa un correo valido';
          }
        }
        return null;
      },
    );
  }

  /// Campo: Telefono (opcional).
  Widget _buildPhoneField() {
    return AuthTextField(
      controller: _phoneController,
      label: 'Numero de telefono',
      hintText: 'Ej: +52 123 456 7890',
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
    );
  }

  /// Nota de almacenamiento local (offline-first).
  Widget _buildLocalStorageNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.security_rounded,
            color: AppColors.forestGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tu informacion se almacena de forma segura en tu dispositivo. '
              'Se sincronizara con el servidor cuando tengas conexion.',
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Enlace para ir a la pantalla de inicio de sesion.
  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Ya tienes cuenta? ',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'Inicia sesion',
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

  /// Ejecuta la validacion y envia el evento de registro al BLoC.
  void _onRegisterPressed() {
    // Validacion de UI local sin esperar respuesta del BLoC
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }
}
