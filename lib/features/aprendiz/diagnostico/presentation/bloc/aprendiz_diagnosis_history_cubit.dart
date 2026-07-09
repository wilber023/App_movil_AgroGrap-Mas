import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../agricultor/diagnosis/domain/entities/diagnosis_entity.dart';
import '../../domain/usecases/get_diagnosis_history_aprendiz_usecase.dart';

sealed class AprendizDiagnosisHistoryState extends Equatable {
  const AprendizDiagnosisHistoryState();
  @override
  List<Object?> get props => [];
}

final class AprendizDiagnosisHistoryLoading extends AprendizDiagnosisHistoryState {
  const AprendizDiagnosisHistoryLoading();
}

final class AprendizDiagnosisHistoryLoaded extends AprendizDiagnosisHistoryState {
  final List<DiagnosisEntity> diagnoses;
  const AprendizDiagnosisHistoryLoaded(this.diagnoses);
  @override
  List<Object?> get props => [diagnoses];
}

final class AprendizDiagnosisHistoryEmpty extends AprendizDiagnosisHistoryState {
  const AprendizDiagnosisHistoryEmpty();
}

final class AprendizDiagnosisHistoryError extends AprendizDiagnosisHistoryState {
  final String message;
  const AprendizDiagnosisHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}

class AprendizDiagnosisHistoryCubit extends Cubit<AprendizDiagnosisHistoryState> {
  final GetDiagnosisHistoryAprendizUseCase getDiagnosisHistoryUseCase;

  AprendizDiagnosisHistoryCubit({required this.getDiagnosisHistoryUseCase})
      : super(const AprendizDiagnosisHistoryLoading());

  Future<void> loadHistory() async {
    emit(const AprendizDiagnosisHistoryLoading());
    final result = await getDiagnosisHistoryUseCase(const NoParams());

    result.fold(
      (failure) => emit(AprendizDiagnosisHistoryError(failure.message)),
      (diagnoses) {
        if (diagnoses.isEmpty) {
          emit(const AprendizDiagnosisHistoryEmpty());
        } else {
          emit(AprendizDiagnosisHistoryLoaded(diagnoses));
        }
      },
    );
  }
}
