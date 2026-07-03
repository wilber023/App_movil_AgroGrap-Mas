import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/treatment_entity.dart';
import '../../domain/usecases/treatment_usecases.dart';

// -- Events --
sealed class TreatmentEvent extends Equatable {
  const TreatmentEvent();
  @override
  List<Object?> get props => [];
}

final class TreatmentAgendaRequested extends TreatmentEvent {
  const TreatmentAgendaRequested();
}

final class TreatmentStepCompleted extends TreatmentEvent {
  final String treatmentId;
  final String stepId;
  const TreatmentStepCompleted({
    required this.treatmentId,
    required this.stepId,
  });
  @override
  List<Object?> get props => [treatmentId, stepId];
}

// -- States --
sealed class TreatmentState extends Equatable {
  const TreatmentState();
  @override
  List<Object?> get props => [];
}

final class TreatmentInitial extends TreatmentState {
  const TreatmentInitial();
}

final class TreatmentLoading extends TreatmentState {
  const TreatmentLoading();
}

final class TreatmentAgendaLoaded extends TreatmentState {
  final List<TreatmentEntity> treatments;
  const TreatmentAgendaLoaded({required this.treatments});
  @override
  List<Object?> get props => [treatments];
}

final class TreatmentStepMarked extends TreatmentState {
  const TreatmentStepMarked();
}

final class TreatmentFailure extends TreatmentState {
  final String message;
  const TreatmentFailure({required this.message});
  @override
  List<Object?> get props => [message];
}

// -- Bloc --
class TreatmentBloc extends Bloc<TreatmentEvent, TreatmentState> {
  final GetTreatmentAgendaUseCase _getAgendaUseCase;
  final MarkStepCompleteUseCase _markStepCompleteUseCase;

  TreatmentBloc({
    required GetTreatmentAgendaUseCase getAgendaUseCase,
    required MarkStepCompleteUseCase markStepCompleteUseCase,
  })  : _getAgendaUseCase = getAgendaUseCase,
        _markStepCompleteUseCase = markStepCompleteUseCase,
        super(const TreatmentInitial()) {
    on<TreatmentAgendaRequested>(_onLoadAgenda);
    on<TreatmentStepCompleted>(_onMarkStep);
  }

  Future<void> _onLoadAgenda(
      TreatmentAgendaRequested event, Emitter<TreatmentState> emit) async {
    emit(const TreatmentLoading());
    final result = await _getAgendaUseCase(const NoParams());
    result.fold(
      (f) => emit(TreatmentFailure(message: f.message)),
      (list) => emit(TreatmentAgendaLoaded(treatments: list)),
    );
  }

  Future<void> _onMarkStep(
      TreatmentStepCompleted event, Emitter<TreatmentState> emit) async {
    final result = await _markStepCompleteUseCase(
      MarkStepCompleteParams(
        treatmentId: event.treatmentId,
        stepId: event.stepId,
      ),
    );
    result.fold(
      (f) => emit(TreatmentFailure(message: f.message)),
      (_) {
        emit(const TreatmentStepMarked());
        add(const TreatmentAgendaRequested());
      },
    );
  }
}
