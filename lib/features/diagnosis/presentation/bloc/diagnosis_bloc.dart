import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/diagnosis_entity.dart';
import '../../domain/usecases/diagnosis_usecases.dart';

// -- Events --
sealed class DiagnosisEvent extends Equatable {
  const DiagnosisEvent();
  @override
  List<Object?> get props => [];
}

final class DiagnosisAnalyzeRequested extends DiagnosisEvent {
  final String imagePath;
  const DiagnosisAnalyzeRequested({required this.imagePath});
  @override
  List<Object?> get props => [imagePath];
}

final class DiagnosisHistoryRequested extends DiagnosisEvent {
  const DiagnosisHistoryRequested();
}

final class DiagnosisReset extends DiagnosisEvent {
  const DiagnosisReset();
}

// -- States --
sealed class DiagnosisState extends Equatable {
  const DiagnosisState();
  @override
  List<Object?> get props => [];
}

final class DiagnosisInitial extends DiagnosisState {
  const DiagnosisInitial();
}

final class DiagnosisAnalyzing extends DiagnosisState {
  const DiagnosisAnalyzing();
}

final class DiagnosisLoadingHistory extends DiagnosisState {
  const DiagnosisLoadingHistory();
}

final class DiagnosisResultLoaded extends DiagnosisState {
  final DiagnosisEntity diagnosis;
  const DiagnosisResultLoaded({required this.diagnosis});
  @override
  List<Object?> get props => [diagnosis];
}

final class DiagnosisHistoryLoaded extends DiagnosisState {
  final List<DiagnosisHistoryItem> items;
  const DiagnosisHistoryLoaded({required this.items});
  @override
  List<Object?> get props => [items];
}

final class DiagnosisFailure extends DiagnosisState {
  final String message;
  const DiagnosisFailure({required this.message});
  @override
  List<Object?> get props => [message];
}

// -- Bloc --
class DiagnosisBloc extends Bloc<DiagnosisEvent, DiagnosisState> {
  final AnalyzeCropUseCase _analyzeCropUseCase;
  final GetDiagnosisHistoryUseCase _getHistoryUseCase;

  DiagnosisBloc({
    required AnalyzeCropUseCase analyzeCropUseCase,
    required GetDiagnosisHistoryUseCase getHistoryUseCase,
  })  : _analyzeCropUseCase = analyzeCropUseCase,
        _getHistoryUseCase = getHistoryUseCase,
        super(const DiagnosisInitial()) {
    on<DiagnosisAnalyzeRequested>(_onAnalyze);
    on<DiagnosisHistoryRequested>(_onLoadHistory);
    on<DiagnosisReset>(_onReset);
  }

  Future<void> _onAnalyze(
      DiagnosisAnalyzeRequested event, Emitter<DiagnosisState> emit) async {
    emit(const DiagnosisAnalyzing());
    final result =
        await _analyzeCropUseCase(AnalyzeCropParams(imagePath: event.imagePath));
    result.fold(
      (f) => emit(DiagnosisFailure(message: f.message)),
      (d) => emit(DiagnosisResultLoaded(diagnosis: d)),
    );
  }

  Future<void> _onLoadHistory(
      DiagnosisHistoryRequested event, Emitter<DiagnosisState> emit) async {
    emit(const DiagnosisLoadingHistory());
    final result = await _getHistoryUseCase(const NoParams());
    result.fold(
      (f) => emit(DiagnosisFailure(message: f.message)),
      (items) => emit(DiagnosisHistoryLoaded(items: items)),
    );
  }

  void _onReset(DiagnosisReset event, Emitter<DiagnosisState> emit) {
    emit(const DiagnosisInitial());
  }
}
