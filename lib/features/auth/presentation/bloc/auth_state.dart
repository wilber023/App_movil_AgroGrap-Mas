// =============================================================================
// Feature: Auth -- Estados del BLoC
// =============================================================================
// Capa: Presentation
// Cada estado representa una condicion de la UI de autenticacion.
// =============================================================================

import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

/// Clase base sellada para todos los estados de autenticacion.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial: no se ha verificado la sesion aun.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado de carga: se esta procesando login, registro o verificacion.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Estado de sesion activa: el usuario esta autenticado.
final class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Estado sin sesion: no hay usuario autenticado.
/// Se muestra la pantalla de Bienvenida (Stitch: "AgroGraph-MAS - Splash").
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Estado de error: fallo en login, registro u otra operacion.
final class AuthFailureState extends AuthState {
  final String message;

  const AuthFailureState({required this.message});

  @override
  List<Object?> get props => [message];
}
