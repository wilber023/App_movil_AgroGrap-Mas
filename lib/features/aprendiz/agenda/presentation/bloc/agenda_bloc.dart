import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/agenda_activity_entity.dart';
import '../../domain/entities/agenda_overview_entity.dart';
import '../../domain/usecases/complete_agenda_activity_usecase.dart';
import '../../domain/usecases/get_agenda_overview_usecase.dart';
import '../../domain/usecases/postpone_agenda_activity_usecase.dart';

// -- Events --
sealed class AgendaEvent extends Equatable {
  const AgendaEvent();
  @override
  List<Object?> get props => [];
}

final class AgendaOverviewRequested extends AgendaEvent {
  const AgendaOverviewRequested();
}

final class AgendaDaySelected extends AgendaEvent {
  final DateTime day;
  const AgendaDaySelected(this.day);
  @override
  List<Object?> get props => [day];
}

final class AgendaMonthChanged extends AgendaEvent {
  final int monthDelta;
  const AgendaMonthChanged(this.monthDelta);
  @override
  List<Object?> get props => [monthDelta];
}

final class AgendaActivityCompleted extends AgendaEvent {
  final String activityId;
  const AgendaActivityCompleted(this.activityId);
  @override
  List<Object?> get props => [activityId];
}

final class AgendaActivityPostponed extends AgendaEvent {
  final String activityId;
  final String reason;
  const AgendaActivityPostponed({required this.activityId, required this.reason});
  @override
  List<Object?> get props => [activityId, reason];
}

// -- States --
sealed class AgendaState extends Equatable {
  const AgendaState();
  @override
  List<Object?> get props => [];
}

final class AgendaInitial extends AgendaState {
  const AgendaInitial();
}

final class AgendaLoading extends AgendaState {
  const AgendaLoading();
}

final class AgendaLoaded extends AgendaState {
  final AgendaOverviewEntity overview;
  final DateTime selectedDay;
  final DateTime visibleMonth;
  final bool isProcessingAction;
  final String? actionError;

  const AgendaLoaded({
    required this.overview,
    required this.selectedDay,
    required this.visibleMonth,
    this.isProcessingAction = false,
    this.actionError,
  });

  AgendaLoaded copyWith({
    AgendaOverviewEntity? overview,
    DateTime? selectedDay,
    DateTime? visibleMonth,
    bool? isProcessingAction,
    String? actionError,
    bool clearActionError = false,
  }) {
    return AgendaLoaded(
      overview: overview ?? this.overview,
      selectedDay: selectedDay ?? this.selectedDay,
      visibleMonth: visibleMonth ?? this.visibleMonth,
      isProcessingAction: isProcessingAction ?? this.isProcessingAction,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [overview, selectedDay, visibleMonth, isProcessingAction, actionError];
}

final class AgendaFailure extends AgendaState {
  final String message;
  const AgendaFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// -- Bloc --
class AgendaBloc extends Bloc<AgendaEvent, AgendaState> {
  final GetAgendaOverviewUseCase getAgendaOverviewUseCase;
  final CompleteAgendaActivityUseCase completeAgendaActivityUseCase;
  final PostponeAgendaActivityUseCase postponeAgendaActivityUseCase;

  AgendaBloc({
    required this.getAgendaOverviewUseCase,
    required this.completeAgendaActivityUseCase,
    required this.postponeAgendaActivityUseCase,
  }) : super(const AgendaInitial()) {
    on<AgendaOverviewRequested>(_onOverviewRequested);
    on<AgendaDaySelected>(_onDaySelected);
    on<AgendaMonthChanged>(_onMonthChanged);
    on<AgendaActivityCompleted>(_onActivityCompleted);
    on<AgendaActivityPostponed>(_onActivityPostponed);
  }

  Future<void> _onOverviewRequested(
    AgendaOverviewRequested event,
    Emitter<AgendaState> emit,
  ) async {
    emit(const AgendaLoading());
    final result = await getAgendaOverviewUseCase(const NoParams());
    final today = DateTime.now();
    result.fold(
      (failure) => emit(AgendaFailure(failure.message)),
      (overview) => emit(AgendaLoaded(
        overview: overview,
        selectedDay: DateTime(today.year, today.month, today.day),
        visibleMonth: DateTime(today.year, today.month),
      )),
    );
  }

  void _onDaySelected(AgendaDaySelected event, Emitter<AgendaState> emit) {
    final current = state;
    if (current is! AgendaLoaded) return;
    emit(current.copyWith(
      selectedDay: event.day,
      visibleMonth: DateTime(event.day.year, event.day.month),
      clearActionError: true,
    ));
  }

  void _onMonthChanged(AgendaMonthChanged event, Emitter<AgendaState> emit) {
    final current = state;
    if (current is! AgendaLoaded) return;
    final newMonth = DateTime(
      current.visibleMonth.year,
      current.visibleMonth.month + event.monthDelta,
    );
    emit(current.copyWith(visibleMonth: newMonth));
  }

  Future<void> _onActivityCompleted(
    AgendaActivityCompleted event,
    Emitter<AgendaState> emit,
  ) async {
    final current = state;
    if (current is! AgendaLoaded) return;

    emit(current.copyWith(isProcessingAction: true, clearActionError: true));
    final result = await completeAgendaActivityUseCase(
      CompleteAgendaActivityParams(activityId: event.activityId),
    );
    await _handleActionResult(result, current, emit);
  }

  Future<void> _onActivityPostponed(
    AgendaActivityPostponed event,
    Emitter<AgendaState> emit,
  ) async {
    final current = state;
    if (current is! AgendaLoaded) return;

    emit(current.copyWith(isProcessingAction: true, clearActionError: true));
    final result = await postponeAgendaActivityUseCase(
      PostponeAgendaActivityParams(activityId: event.activityId, reason: event.reason),
    );
    await _handleActionResult(result, current, emit);
  }

  Future<void> _handleActionResult(
    Either<Failure, AgendaActivityEntity> result,
    AgendaLoaded previous,
    Emitter<AgendaState> emit,
  ) async {
    await result.fold(
      (failure) async => emit(previous.copyWith(
        isProcessingAction: false,
        actionError: failure.message,
      )),
      (_) async {
        final refreshed = await getAgendaOverviewUseCase(const NoParams());
        refreshed.fold(
          (failure) => emit(previous.copyWith(
            isProcessingAction: false,
            actionError: failure.message,
          )),
          (overview) => emit(previous.copyWith(
            overview: overview,
            isProcessingAction: false,
            clearActionError: true,
          )),
        );
      },
    );
  }
}
