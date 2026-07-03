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
      (_) => emit(SplashNavigateToProfileSelect()),
      (user) {
        if (!user.isAuthenticated) {
          emit(SplashNavigateToProfileSelect());
          return;
        }

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
