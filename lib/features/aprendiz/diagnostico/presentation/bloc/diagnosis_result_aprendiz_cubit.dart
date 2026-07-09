import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../agricultor/diagnosis/domain/entities/llm_response_entity.dart';
import '../../../cultivo/domain/entities/crop_activity_entity.dart';
import '../../domain/usecases/accept_guided_action_usecase.dart';
import '../../domain/usecases/save_diagnosis_llm_response_usecase.dart';

sealed class DiagnosisResultAprendizState extends Equatable {
  const DiagnosisResultAprendizState();
  @override
  List<Object?> get props => [];
}

final class DiagnosisResultInitial extends DiagnosisResultAprendizState {
  const DiagnosisResultInitial();
}

final class DiagnosisResultLoading extends DiagnosisResultAprendizState {
  const DiagnosisResultLoading();
}

final class AgendaUpdated extends DiagnosisResultAprendizState {
  final List<CropActivityEntity> newActivities;
  const AgendaUpdated(this.newActivities);
  @override
  List<Object?> get props => [newActivities];
}

final class DiagnosisResultError extends DiagnosisResultAprendizState {
  final String message;
  const DiagnosisResultError(this.message);
  @override
  List<Object?> get props => [message];
}

class DiagnosisResultAprendizCubit extends Cubit<DiagnosisResultAprendizState> {
  final AcceptGuidedActionUseCase acceptGuidedActionUseCase;
  final SaveDiagnosisLlmResponseUseCase saveDiagnosisLlmResponseUseCase;

  DiagnosisResultAprendizCubit({
    required this.acceptGuidedActionUseCase,
    required this.saveDiagnosisLlmResponseUseCase,
  }) : super(const DiagnosisResultInitial());

  Future<void> acceptAction(String activityId) async {
    emit(const DiagnosisResultLoading());
    final result = await acceptGuidedActionUseCase(AcceptGuidedActionParams(activityId: activityId));

    result.fold(
      (failure) => emit(DiagnosisResultError(failure.message)),
      (activities) => emit(AgendaUpdated(activities)),
    );
  }

  /// Persiste la explicación del LLM en el historial una vez resuelta,
  /// sin afectar el estado visible (la sección LLM tiene su propio cubit).
  Future<void> saveLlmResponse({required String diagnosisId, required LlmResponseEntity llmResponse}) {
    return saveDiagnosisLlmResponseUseCase(
      SaveDiagnosisLlmResponseParams(diagnosisId: diagnosisId, llmResponse: llmResponse),
    );
  }
}
