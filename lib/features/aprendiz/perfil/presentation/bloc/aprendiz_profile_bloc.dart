import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/aprendiz_profile_overview_entity.dart';
import '../../domain/usecases/get_aprendiz_profile_overview_usecase.dart';
import '../../domain/usecases/set_offline_mode_usecase.dart';

// -- Events --
sealed class AprendizProfileEvent extends Equatable {
  const AprendizProfileEvent();
  @override
  List<Object?> get props => [];
}

final class ProfileOverviewRequested extends AprendizProfileEvent {
  const ProfileOverviewRequested();
}

final class OfflineModeToggled extends AprendizProfileEvent {
  final bool enabled;
  const OfflineModeToggled(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

// -- States --
sealed class AprendizProfileState extends Equatable {
  const AprendizProfileState();
  @override
  List<Object?> get props => [];
}

final class ProfileInitial extends AprendizProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends AprendizProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends AprendizProfileState {
  final AprendizProfileOverviewEntity overview;
  const ProfileLoaded(this.overview);
  @override
  List<Object?> get props => [overview];
}

final class ProfileFailure extends AprendizProfileState {
  final String message;
  const ProfileFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// -- Bloc --
class AprendizProfileBloc extends Bloc<AprendizProfileEvent, AprendizProfileState> {
  final GetAprendizProfileOverviewUseCase getProfileOverviewUseCase;
  final SetOfflineModeUseCase setOfflineModeUseCase;

  AprendizProfileBloc({
    required this.getProfileOverviewUseCase,
    required this.setOfflineModeUseCase,
  }) : super(const ProfileInitial()) {
    on<ProfileOverviewRequested>(_onOverviewRequested);
    on<OfflineModeToggled>(_onOfflineModeToggled);
  }

  Future<void> _onOverviewRequested(
    ProfileOverviewRequested event,
    Emitter<AprendizProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    final result = await getProfileOverviewUseCase(const NoParams());
    result.fold(
      (failure) => emit(ProfileFailure(failure.message)),
      (overview) => emit(ProfileLoaded(overview)),
    );
  }

  Future<void> _onOfflineModeToggled(
    OfflineModeToggled event,
    Emitter<AprendizProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    // Optimista: la UI refleja el cambio de inmediato; si falla, se revierte
    // recargando el overview real.
    emit(ProfileLoaded(_withOfflineMode(current.overview, event.enabled)));

    final result = await setOfflineModeUseCase(SetOfflineModeParams(enabled: event.enabled));
    result.fold(
      (failure) => add(const ProfileOverviewRequested()),
      (_) {},
    );
  }

  AprendizProfileOverviewEntity _withOfflineMode(AprendizProfileOverviewEntity overview, bool enabled) {
    return AprendizProfileOverviewEntity(
      userName: overview.userName,
      userInitials: overview.userInitials,
      email: overview.email,
      progress: overview.progress,
      activitySummary: overview.activitySummary,
      weeklyGoals: overview.weeklyGoals,
      recommendation: overview.recommendation,
      offlineModeEnabled: enabled,
    );
  }
}
