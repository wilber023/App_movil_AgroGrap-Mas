import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/usecases/get_dashboard_usecase.dart';

// -- Events --
sealed class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

final class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested();
}

final class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}

// -- States --
sealed class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoaded extends HomeState {
  final DashboardEntity dashboard;
  const HomeLoaded({required this.dashboard});
  @override
  List<Object?> get props => [dashboard];
}

final class HomeFailure extends HomeState {
  final String message;
  const HomeFailure({required this.message});
  @override
  List<Object?> get props => [message];
}

// -- Bloc --
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetDashboardUseCase _getDashboardUseCase;

  HomeBloc({required GetDashboardUseCase getDashboardUseCase})
      : _getDashboardUseCase = getDashboardUseCase,
        super(const HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(HomeLoadRequested event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    final result = await _getDashboardUseCase(const NoParams());
    result.fold(
      (f) => emit(HomeFailure(message: f.message)),
      (d) => emit(HomeLoaded(dashboard: d)),
    );
  }

  Future<void> _onRefresh(HomeRefreshRequested event, Emitter<HomeState> emit) async {
    final result = await _getDashboardUseCase(const NoParams());
    result.fold(
      (f) => emit(HomeFailure(message: f.message)),
      (d) => emit(HomeLoaded(dashboard: d)),
    );
  }
}
