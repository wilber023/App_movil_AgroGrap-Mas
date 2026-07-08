// =============================================================================
// Feature: Auth -- Cubit de la Pantalla Splash
// =============================================================================
// Capa: Presentation / Bloc
// Decide el destino de navegación al iniciar la app basándose en la sesión
// cacheada localmente y el rol real del usuario (no en una preferencia guardada).
//
// Cambio de diseño:
//   Antes: usaba getSelectedProfileType() (preferencia manual guardada).
//   Ahora: usa user.role del cache (fuente de verdad del backend), lo que
//   garantiza que el destino siempre coincide con el tipo de cuenta real.
// =============================================================================

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_saved_session_usecase.dart';

sealed class SplashState {}

class SplashInitial extends SplashState {}

class SplashNavigateToProfileSelect extends SplashState {}

class SplashNavigateToAgricultorHome extends SplashState {}

class SplashNavigateToAprendizHome extends SplashState {}

class SplashCubit extends Cubit<SplashState> {
  final GetSavedSessionUseCase getSavedSessionUseCase;

  SplashCubit({required this.getSavedSessionUseCase}) : super(SplashInitial());

  Future<void> checkSession() async {
    // Garantizar al menos 2.5 s de duración del splash.
    final minDelay = Future.delayed(const Duration(milliseconds: 2500));

    final sessionResult = await getSavedSessionUseCase(const NoParams());

    await minDelay;

    sessionResult.fold(
      (failure) {
        debugPrint('[AUTH] SplashCubit: sin sesion valida (${failure.message}) -> Login');
        emit(SplashNavigateToProfileSelect());
      },
      (user) {
        debugPrint(
          '[AUTH] SplashCubit: sesion valida, user=${user.id} role=${user.role} '
          '-> navegando directo (sin pedir login)',
        );
        // NOTA: no se valida user.isAuthenticated aqui a proposito.
        // UserEntity.accessToken nunca esta poblado en un usuario que viene
        // del cache de Hive (UserModel.toCacheJson() lo excluye
        // deliberadamente por seguridad — MASVS-STORAGE, ver ese archivo).
        // Validar isAuthenticated sobre este "user" siempre daba false y
        // mandaba al Login sin importar si la sesion era valida. La
        // validacion real (token existe + no vencido, con refresh si hace
        // falta) ya ocurrio dentro de getSavedSessionUseCase: llegar aqui
        // a la rama Right() YA significa sesion valida.

        // Usar el rol real del backend (guardado en cache) como única fuente
        // de verdad para el destino de navegación.
        if (user.isAgricultor) {
          emit(SplashNavigateToAgricultorHome());
        } else if (user.isAprendiz) {
          emit(SplashNavigateToAprendizHome());
        } else {
          // Rol desconocido, admin, o usuario sin rol definido → profile select.
          emit(SplashNavigateToProfileSelect());
        }
      },
    );
  }
}
