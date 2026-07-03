// =============================================================================
// Feature: Auth -- Caso de Uso: Validar Formulario de Registro
// =============================================================================
// Capa: Domain
// Responsabilidad unica: validar los campos del formulario de registro.
// Retorna un mapa de errores por campo, vacio si todo es valido.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Resultado de la validacion — mapa campo→mensaje.
/// Si [errors] esta vacio, el formulario es valido.
class RegisterFormValidation extends Equatable {
  final Map<String, String> errors;
  const RegisterFormValidation({this.errors = const {}});

  bool get isValid => errors.isEmpty;

  @override
  List<Object?> get props => [errors];
}

/// Parametros del formulario de registro a validar.
class RegisterFormData extends Equatable {
  final String firstName;
  final String lastName;
  final String username;
  final String password;
  final String confirmPassword;

  const RegisterFormData({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.confirmPassword,
  });

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props =>
      [firstName, lastName, username, password, confirmPassword];
}

/// Valida el formulario de registro de forma sincrona.
///
/// Toda la logica de validacion vive aqui, no en el widget.
class ValidateRegisterFormUseCase {
  const ValidateRegisterFormUseCase();

  RegisterFormValidation call(RegisterFormData data) {
    final errors = <String, String>{};

    // Nombre
    if (data.firstName.trim().isEmpty) {
      errors['firstName'] = 'Ingresa tu nombre';
    } else if (data.firstName.trim().length < 2) {
      errors['firstName'] = 'El nombre debe tener al menos 2 caracteres';
    }

    // Apellido
    if (data.lastName.trim().isEmpty) {
      errors['lastName'] = 'Ingresa tu apellido';
    } else if (data.lastName.trim().length < 2) {
      errors['lastName'] = 'El apellido debe tener al menos 2 caracteres';
    }

    // Usuario
    if (data.username.trim().isEmpty) {
      errors['username'] = 'Ingresa un nombre de usuario';
    } else if (data.username.trim().length < 3) {
      errors['username'] = 'El usuario debe tener al menos 3 caracteres';
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(data.username.trim())) {
      errors['username'] = 'Solo letras, numeros y guion bajo';
    }

    // Contrasena
    if (data.password.isEmpty) {
      errors['password'] = 'Ingresa una contrasena';
    } else if (data.password.length < 6) {
      errors['password'] = 'La contrasena debe tener al menos 6 caracteres';
    }

    // Confirmar contrasena
    if (data.confirmPassword.isEmpty) {
      errors['confirmPassword'] = 'Confirma tu contrasena';
    } else if (data.password != data.confirmPassword) {
      errors['confirmPassword'] = 'Las contrasenas no coinciden';
    }

    return RegisterFormValidation(errors: errors);
  }
}
