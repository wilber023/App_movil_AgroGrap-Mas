import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecases/usecase.dart';
import '../../../../../core/network/network_info.dart';
import '../../../cultivo/domain/entities/crop_activity_entity.dart';
import '../../../cultivo/domain/usecases/postpone_activity_usecase.dart';
import '../../domain/entities/aprendiz_home_overview_entity.dart';
import '../../domain/usecases/get_aprendiz_home_overview_usecase.dart';

// -- Events --
sealed class AprendizHomeEvent extends Equatable {
  const AprendizHomeEvent();
  @override
  List<Object?> get props => [];
}

final class HomeOverviewRequested extends AprendizHomeEvent {
  const HomeOverviewRequested();
}

final class DueInspectionModalShown extends AprendizHomeEvent {
  const DueInspectionModalShown();
}

final class InspectionPostponed extends AprendizHomeEvent {
  final String activityId;
  const InspectionPostponed(this.activityId);
  @override
  List<Object?> get props => [activityId];
}

// -- States --
sealed class AprendizHomeState extends Equatable {
  const AprendizHomeState();
  @override
  List<Object?> get props => [];
}

final class HomeInitial extends AprendizHomeState {
  const HomeInitial();
}

final class HomeLoading extends AprendizHomeState {
  const HomeLoading();
}

final class HomeLoaded extends AprendizHomeState {
  final AprendizHomeOverviewEntity overview;
  final CropActivityEntity? dueInspection;
  final bool modalAlreadyShown;
  final bool isOffline;

  const HomeLoaded({
    required this.overview,
    required this.dueInspection,
    this.modalAlreadyShown = false,
    this.isOffline = false,
  });

  HomeLoaded copyWith({
    AprendizHomeOverviewEntity? overview,
    CropActivityEntity? dueInspection,
    bool? modalAlreadyShown,
    bool? isOffline,
    bool clearDueInspection = false,
  }) {
    return HomeLoaded(
      overview: overview ?? this.overview,
      dueInspection: clearDueInspection ? null : (dueInspection ?? this.dueInspection),
      modalAlreadyShown: modalAlreadyShown ?? this.modalAlreadyShown,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  List<Object?> get props => [overview, dueInspection, modalAlreadyShown, isOffline];
}

final class HomeFailure extends AprendizHomeState {
  final String message;
  const HomeFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// -- Bloc --
class AprendizHomeBloc extends Bloc<AprendizHomeEvent, AprendizHomeState> {
  final GetAprendizHomeOverviewUseCase getHomeOverviewUseCase;
  final PostponeActivityUseCase postponeActivityUseCase;
  final NetworkInfo networkInfo;

  AprendizHomeBloc({
    required this.getHomeOverviewUseCase,
    required this.postponeActivityUseCase,
    required this.networkInfo,
  }) : super(const HomeInitial()) {
    on<HomeOverviewRequested>(_onOverviewRequested);
    on<DueInspectionModalShown>(_onModalShown);
    on<InspectionPostponed>(_onInspectionPostponed);
  }

  Future<void> _onOverviewRequested(
    HomeOverviewRequested event,
    Emitter<AprendizHomeState> emit,
  ) async {
    emit(const HomeLoading());

    try {
      final isOffline = !(await networkInfo.isConnected);
      final overviewResult = await getHomeOverviewUseCase(const NoParams());

      final previous = state;
      final modalAlreadyShown = previous is HomeLoaded ? previous.modalAlreadyShown : false;

      overviewResult.fold(
        (failure) => emit(HomeFailure(failure.message)),
        (overview) => emit(HomeLoaded(
          overview: overview,
          dueInspection: overview.dueInspection,
          modalAlreadyShown: modalAlreadyShown,
          isOffline: isOffline,
        )),
      );
    } catch (e) {
      // Cualquier falla no prevista (p. ej. una excepcion no envuelta en
      // Either por alguno de los modulos compuestos) termina en un estado
      // visible con reintento, nunca en un loading atascado en silencio.
      emit(HomeFailure('No se pudo cargar el inicio: $e'));
    }
  }

  void _onModalShown(DueInspectionModalShown event, Emitter<AprendizHomeState> emit) {
    final current = state;
    if (current is! HomeLoaded) return;
    emit(current.copyWith(modalAlreadyShown: true));
  }

  Future<void> _onInspectionPostponed(
    InspectionPostponed event,
    Emitter<AprendizHomeState> emit,
  ) async {
    try {
      final result = await postponeActivityUseCase(
        PostponeActivityParams(activityId: event.activityId, reason: 'Pospuesto desde inicio'),
      );
      await result.fold(
        (failure) async => emit(HomeFailure(failure.message)),
        (_) async => _onOverviewRequested(const HomeOverviewRequested(), emit),
      );
    } catch (e) {
      emit(HomeFailure('No se pudo posponer la inspección: $e'));
    }
  }
}
