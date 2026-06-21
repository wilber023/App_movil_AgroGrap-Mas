// =============================================================================
// Feature: Auth -- BLoC Principal
// =============================================================================
// Capa: Presentation
// El BLoC no tiene lógica de negocio propia. Delega en los UseCases del
// dominio y transforma el resultado (Either) en estados de la UI.
//
// Reglas de acceso por rol:
//   • El login valida que el rol devuelto por la API coincida con el perfil
//     seleccionado en la UI. Acceso cruzado = error, nunca éxito.
//   • El registro NO inicia sesión automáticamente: limpia la sesión
//     recién creada y emite [AuthRegistrationSuccess] para que la UI
//     redirija al Login.
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/profile_type.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

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

  // ---------------------------------------------------------------------------
  // Login — valida que el rol de la API coincida con el perfil seleccionado
  // ---------------------------------------------------------------------------

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _loginUseCase(
      LoginParams(username: event.username, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthFailureState(message: failure.message)),
      (user) {
        // Convertir el rol real de la API a ProfileType.
        final actualProfileType = _roleToProfileType(user.role);

        // Rol desconocido (ej. admin) → no compatible con el app móvil.
        if (actualProfileType == null) {
          emit(const AuthFailureState(
            message: 'Este tipo de cuenta no puede acceder desde la app móvil.',
          ));
          return;
        }

        // Acceso cruzado de perfiles → bloquear con mensaje claro.
        if (actualProfileType != event.profileType) {
          final actualName = actualProfileType.displayName;
          emit(AuthFailureState(
            message:
                'Esta cuenta es de tipo "$actualName". Selecciona el perfil correcto para iniciar sesión.',
          ));
          return;
        }

        emit(AuthAuthenticated(user: user, profileType: actualProfileType));
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Register — NO inicia sesión; limpia la sesión y redirige al Login
  // ---------------------------------------------------------------------------

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
        profileType: event.profileType,
        email: event.email,
        phone: event.phone,
      ),
    );

    await result.fold(
      (failure) async => emit(AuthFailureState(message: failure.message)),
      (user) async {
        // Limpiar la sesión persistida por el registro: el usuario debe
        // autenticarse manualmente. Esto también invalida los tokens en
        // el servidor (blacklist) para mayor seguridad.
        await _logoutUseCase(const NoParams());
        emit(AuthRegistrationSuccess(fullName: user.fullName));
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Check session (splash)
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Handlers sin lógica activa (extensión futura)
  // ---------------------------------------------------------------------------

  Future<void> _onRefreshSessionRequested(
    AuthRefreshSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    // El refresco automático se maneja vía AuthInterceptor de Dio.
    // Este handler queda como punto de extensión para casos explícitos.
  }

  Future<void> _onProfileTypeSelected(
    AuthProfileTypeSelected event,
    Emitter<AuthState> emit,
  ) async {
    // La UI navega directamente al formulario correcto.
    // Sin cambio de estado de autenticación.
  }

  // ---------------------------------------------------------------------------
  // Helper: convierte el rol del backend a ProfileType del dominio
  // ---------------------------------------------------------------------------

  ProfileType? _roleToProfileType(String? role) => switch (role) {
        'agricultor' => ProfileType.agricultor,
        'aprendiz_agricola' => ProfileType.aprendizAgricola,
        _ => null, // 'admin' u otro rol no soportado en mobile
      };
}
