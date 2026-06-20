// =============================================================================
// Feature: Auth -- Eventos del BLoC
// =============================================================================
// Capa: Presentation
// Cada evento representa una accion iniciada por el usuario o el sistema.
// =============================================================================

import 'package:equatable/equatable.dart';

import '../../domain/entities/profile_type.dart';

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
  final ProfileType profileType;

  const AuthLoginRequested({
    required this.username,
    required this.password,
    required this.profileType,
  });

  @override
  List<Object?> get props => [username, password, profileType];
}

/// El usuario envio el formulario de registro.
final class AuthRegisterRequested extends AuthEvent {
  final String fullName;
  final String username;
  final String password;
  final ProfileType profileType;
  final String? email;
  final String? phone;

  const AuthRegisterRequested({
    required this.fullName,
    required this.username,
    required this.password,
    required this.profileType,
    this.email,
    this.phone,
  });

  @override
  List<Object?> get props => [fullName, username, password, profileType, email, phone];
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

/// El usuario selecciono un tipo de perfil en la pantalla de seleccion.
final class AuthProfileTypeSelected extends AuthEvent {
  final ProfileType profileType;

  const AuthProfileTypeSelected({required this.profileType});

  @override
  List<Object?> get props => [profileType];
}
