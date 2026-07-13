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

final class TreatmentGenerateFromDiagnosisRequested extends TreatmentEvent {
  final String diagnosisId;
  final String diseaseName;
  final String cropName;
  final String llmDiagnostico;
  final String llmTratamiento;
  final String llmPrevencion;

  const TreatmentGenerateFromDiagnosisRequested({
    required this.diagnosisId,
    required this.diseaseName,
    required this.cropName,
    required this.llmDiagnostico,
    required this.llmTratamiento,
    required this.llmPrevencion,
  });

  @override
  List<Object?> get props =>
      [diagnosisId, diseaseName, cropName, llmDiagnostico, llmTratamiento, llmPrevencion];
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

final class TreatmentStepRescheduled extends TreatmentEvent {
  final String treatmentId;
  final String stepId;
  final DateTime newDate;
  const TreatmentStepRescheduled({
    required this.treatmentId,
    required this.stepId,
    required this.newDate,
  });
  @override
  List<Object?> get props => [treatmentId, stepId, newDate];
}

final class TreatmentRemindersToggled extends TreatmentEvent {
  final String treatmentId;
  final bool active;
  const TreatmentRemindersToggled({
    required this.treatmentId,
    required this.active,
  });
  @override
  List<Object?> get props => [treatmentId, active];
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
  final GenerateTreatmentFromDiagnosisUseCase _generateFromDiagnosisUseCase;
  final MarkStepCompleteUseCase _markStepCompleteUseCase;
  final RescheduleStepUseCase _rescheduleStepUseCase;
  final SetRemindersActiveUseCase _setRemindersActiveUseCase;

  TreatmentBloc({
    required GetTreatmentAgendaUseCase getAgendaUseCase,
    required GenerateTreatmentFromDiagnosisUseCase generateFromDiagnosisUseCase,
    required MarkStepCompleteUseCase markStepCompleteUseCase,
    required RescheduleStepUseCase rescheduleStepUseCase,
    required SetRemindersActiveUseCase setRemindersActiveUseCase,
  })  : _getAgendaUseCase = getAgendaUseCase,
        _generateFromDiagnosisUseCase = generateFromDiagnosisUseCase,
        _markStepCompleteUseCase = markStepCompleteUseCase,
        _rescheduleStepUseCase = rescheduleStepUseCase,
        _setRemindersActiveUseCase = setRemindersActiveUseCase,
        super(const TreatmentInitial()) {
    on<TreatmentAgendaRequested>(_onLoadAgenda);
    on<TreatmentGenerateFromDiagnosisRequested>(_onGenerateFromDiagnosis);
    on<TreatmentStepCompleted>(_onMarkStep);
    on<TreatmentStepRescheduled>(_onRescheduleStep);
    on<TreatmentRemindersToggled>(_onToggleReminders);
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

  Future<void> _onGenerateFromDiagnosis(
      TreatmentGenerateFromDiagnosisRequested event, Emitter<TreatmentState> emit) async {
    emit(const TreatmentLoading());
    final result = await _generateFromDiagnosisUseCase(GenerateTreatmentFromDiagnosisParams(
      diagnosisId: event.diagnosisId,
      diseaseName: event.diseaseName,
      cropName: event.cropName,
      llmDiagnostico: event.llmDiagnostico,
      llmTratamiento: event.llmTratamiento,
      llmPrevencion: event.llmPrevencion,
    ));
    result.fold(
      (f) => emit(TreatmentFailure(message: f.message)),
      (_) => add(const TreatmentAgendaRequested()),
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

  Future<void> _onRescheduleStep(
      TreatmentStepRescheduled event, Emitter<TreatmentState> emit) async {
    final result = await _rescheduleStepUseCase(
      RescheduleStepParams(
        treatmentId: event.treatmentId,
        stepId: event.stepId,
        newDate: event.newDate,
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

  Future<void> _onToggleReminders(
      TreatmentRemindersToggled event, Emitter<TreatmentState> emit) async {
    final result = await _setRemindersActiveUseCase(
      SetRemindersActiveParams(
        treatmentId: event.treatmentId,
        active: event.active,
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
