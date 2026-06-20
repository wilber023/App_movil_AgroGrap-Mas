// =============================================================================
// Feature: Auth -- Cubit de la Pantalla Splash
// =============================================================================
// Capa: Presentation / Bloc
// Maneja la logica de inicializacion y decide el destino de navegacion
// basado en la sesion y perfil guardados.
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/profile_type.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_saved_session_usecase.dart';

sealed class SplashState {}

class SplashInitial extends SplashState {}

class SplashNavigateToProfileSelect extends SplashState {}

class SplashNavigateToAgricultorHome extends SplashState {}

class SplashFeatureNotReadyYet extends SplashState {
  final ProfileType profileType;
  SplashFeatureNotReadyYet({required this.profileType});
}

class SplashCubit extends Cubit<SplashState> {
  final GetSavedSessionUseCase getSavedSessionUseCase;
  final AuthRepository authRepository;

  SplashCubit({
    required this.getSavedSessionUseCase,
    required this.authRepository,
  }) : super(SplashInitial());

  Future<void> checkSession() async {
    // Garantizar al menos 2.5 segundos de duracion del splash
    final minDelay = Future.delayed(const Duration(milliseconds: 2500));

    final sessionResult = await getSavedSessionUseCase(const NoParams());

    await minDelay;

    sessionResult.fold(
      (failure) {
        emit(SplashNavigateToProfileSelect());
      },
      (user) async {
        if (!user.isAuthenticated) {
          emit(SplashNavigateToProfileSelect());
          return;
        }

        final profileResult = await authRepository.getSelectedProfileType();
        profileResult.fold(
          (failure) {
            emit(SplashNavigateToProfileSelect());
          },
          (profileType) {
            if (profileType == ProfileType.agricultor) {
              emit(SplashNavigateToAgricultorHome());
            } else if (profileType == ProfileType.aprendizAgricola) {
              emit(SplashFeatureNotReadyYet(profileType: profileType!));
            } else {
              emit(SplashNavigateToProfileSelect());
            }
          },
        );
      },
    );
  }
}
