// =============================================================================
// Feature: Auth -- Estados del BLoC
// =============================================================================
// Capa: Presentation
// Cada estado representa una condicion de la UI de autenticacion.
// =============================================================================

import 'package:equatable/equatable.dart';

import '../../domain/entities/profile_type.dart';
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

/// Estado de sesion activa: el usuario esta autenticado como Agricultor.
final class AuthAuthenticated extends AuthState {
  final UserEntity user;
  final ProfileType profileType;

  const AuthAuthenticated({
    required this.user,
    this.profileType = ProfileType.agricultor,
  });

  @override
  List<Object?> get props => [user, profileType];
}

/// Estado sin sesion: no hay usuario autenticado.
/// Se muestra la pantalla de Splash / Seleccion de Perfil.
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

/// Estado cuando el feature del perfil aun no esta implementado.
final class AuthFeatureNotReady extends AuthState {
  final ProfileType profileType;
  final UserEntity? user;

  const AuthFeatureNotReady({required this.profileType, this.user});

  @override
  List<Object?> get props => [profileType, user];
}

/// Estado de registro exitoso: cuenta creada, sesión NO iniciada.
/// La UI debe redirigir al Login para que el usuario autentique manualmente.
final class AuthRegistrationSuccess extends AuthState {
  final String fullName;

  const AuthRegistrationSuccess({required this.fullName});

  @override
  List<Object?> get props => [fullName];
}
