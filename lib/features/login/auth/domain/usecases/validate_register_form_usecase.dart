// =============================================================================
// Feature: Auth -- Caso de Uso: Validar Formulario de Registro
// =============================================================================
// Capa: Domain
// Responsabilidad unica: validar los campos del formulario de registro.
// Retorna un mapa de errores por campo, vacio si todo es valido.
// =============================================================================

import 'package:equatable/equatable.dart';

import '../../../../../core/validators/content_validators.dart';
import '../../../../../core/validators/cross_field_validators.dart';
import '../../../../../core/validators/length_validators.dart';
import '../../../../../core/validators/pattern_validators.dart';
import '../../../../../core/validators/regex_validator.dart';

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

    // Nombre — longitud + contenido (solo letras/espacios/guiones)
    final firstName = data.firstName.trim();
    if (firstName.isEmpty) {
      errors['firstName'] = 'Ingresa tu nombre';
    } else {
      final firstNameError = LengthValidators.range(firstName, min: 2, max: 50, field: 'El nombre') ??
          ContentValidators.safeName(firstName);
      if (firstNameError != null) errors['firstName'] = firstNameError;
    }

    // Apellido — longitud + contenido
    final lastName = data.lastName.trim();
    if (lastName.isEmpty) {
      errors['lastName'] = 'Ingresa tu apellido';
    } else {
      final lastNameError = LengthValidators.range(lastName, min: 2, max: 50, field: 'El apellido') ??
          ContentValidators.safeName(lastName);
      if (lastNameError != null) errors['lastName'] = lastNameError;
    }

    // Usuario — longitud + patron regex (letras, numeros, guion bajo)
    final username = data.username.trim();
    if (username.isEmpty) {
      errors['username'] = 'Ingresa un nombre de usuario';
    } else {
      final usernameError = LengthValidators.range(username, min: 3, max: 30, field: 'El usuario') ??
          RegexValidator.matches(
            username,
            RegExp(r'^[a-zA-Z0-9_]+$'),
            errorMessage: 'Solo letras, numeros y guion bajo',
          );
      if (usernameError != null) errors['username'] = usernameError;
    }

    // Contrasena — fortaleza (min. 8, mayus, minus, numero y simbolo)
    final passwordError = PatternValidators.strongPassword(data.password);
    if (passwordError != null) errors['password'] = passwordError;

    // Confirmar contrasena — validacion cruzada
    if (data.confirmPassword.isEmpty) {
      errors['confirmPassword'] = 'Confirma tu contrasena';
    } else {
      final matchError = CrossFieldValidators.passwordsMatch(data.password, data.confirmPassword);
      if (matchError != null) errors['confirmPassword'] = matchError;
    }

    return RegisterFormValidation(errors: errors);
  }
}
