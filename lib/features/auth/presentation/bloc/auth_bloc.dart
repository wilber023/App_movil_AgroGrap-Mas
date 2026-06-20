// =============================================================================
// Feature: Auth -- BLoC Principal
// =============================================================================
// Capa: Presentation
// Regla: El BLoC no tiene logica de negocio propia. Delega a los
//        UseCases del dominio y transforma el resultado (Either) en
//        estados de la UI.
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC que gestiona el flujo de autenticacion de la aplicacion.
///
/// Maneja los eventos de login, registro, verificacion de sesion y logout.
/// Cada handler delega al UseCase correspondiente y emite el estado
/// resultante para que la UI reaccione.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _logoutUseCase = logoutUseCase,
        super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthCheckSessionRequested>(_onCheckSessionRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthRefreshSessionRequested>(_onRefreshSessionRequested);
    on<AuthProfileTypeSelected>(_onProfileTypeSelected);
  }

  /// Maneja el evento de login.
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _loginUseCase(
      LoginParams(
        username: event.username,
        password: event.password,
      ),
    );

    result.fold(
      (failure) => emit(AuthFailureState(message: failure.message)),
      (user) {
        emit(AuthAuthenticated(user: user, profileType: event.profileType));
      },
    );
  }

  /// Maneja el evento de registro.
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _registerUseCase(
      RegisterParams(
        fullName: event.fullName,
        username: event.username,
        password: event.password,
        email: event.email,
        phone: event.phone,
      ),
    );

    result.fold(
      (failure) => emit(AuthFailureState(message: failure.message)),
      (user) {
        emit(AuthAuthenticated(user: user, profileType: event.profileType));
      },
    );
  }

  /// Maneja la verificacion de sesion al iniciar la app.
  Future<void> _onCheckSessionRequested(
    AuthCheckSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _getCurrentUserUseCase(const NoParams());

    result.fold(
      (_) => emit(const AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  /// Maneja el cierre de sesion.
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _logoutUseCase(const NoParams());

    result.fold(
      (failure) => emit(AuthFailureState(message: failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  /// Maneja el refresco de sesion (placeholder para futuro uso).
  Future<void> _onRefreshSessionRequested(
    AuthRefreshSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    // El refresco de token se manejara via interceptor de Dio.
    // Este handler queda como punto de extension.
  }

  /// Maneja la seleccion de tipo de perfil.
  Future<void> _onProfileTypeSelected(
    AuthProfileTypeSelected event,
    Emitter<AuthState> emit,
  ) async {
    // Solo persiste la seleccion — no cambia estado de autenticacion.
    // La UI navega directamente al formulario de registro/login correspondiente.
  }
}
