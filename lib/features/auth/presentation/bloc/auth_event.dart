// =============================================================================
// Feature: Auth -- Eventos del BLoC
// =============================================================================
// Capa: Presentation
// Cada evento representa una accion iniciada por el usuario o el sistema.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Clase base sellada para todos los eventos de autenticacion.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// El usuario presiono el boton de inicio de sesion.
final class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

/// El usuario envio el formulario de registro.
final class AuthRegisterRequested extends AuthEvent {
  final String fullName;
  final String username;
  final String password;
  final String? email;
  final String? phone;

  const AuthRegisterRequested({
    required this.fullName,
    required this.username,
    required this.password,
    this.email,
    this.phone,
  });

  @override
  List<Object?> get props => [fullName, username, password, email, phone];
}

/// La app verifico si hay una sesion activa al iniciar.
final class AuthCheckSessionRequested extends AuthEvent {
  const AuthCheckSessionRequested();
}

/// El usuario presiono el boton de cerrar sesion.
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// El sistema solicito refrescar el token expirado.
final class AuthRefreshSessionRequested extends AuthEvent {
  const AuthRefreshSessionRequested();
}
