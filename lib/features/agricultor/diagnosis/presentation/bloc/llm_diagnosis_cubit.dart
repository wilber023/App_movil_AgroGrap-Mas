// =============================================================================
// AgroGraph-MAS — LlmDiagnosisCubit
// Estado del enriquecimiento IA en la pantalla de resultado.
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/diagnosis_entity.dart';
import '../../domain/entities/llm_response_entity.dart';
import '../../domain/usecases/get_llm_diagnosis_usecase.dart';

// -- States ------------------------------------------------------------------

sealed class LlmDiagnosisState extends Equatable {
  const LlmDiagnosisState();
  @override
  List<Object?> get props => [];
}

final class LlmDiagnosisIdle extends LlmDiagnosisState {
  const LlmDiagnosisIdle();
}

final class LlmDiagnosisLoading extends LlmDiagnosisState {
  const LlmDiagnosisLoading();
}

final class LlmDiagnosisLoaded extends LlmDiagnosisState {
  final LlmResponseEntity response;
  const LlmDiagnosisLoaded(this.response);
  @override
  List<Object?> get props => [response];
}

final class LlmDiagnosisError extends LlmDiagnosisState {
  final String message;
  const LlmDiagnosisError(this.message);
  @override
  List<Object?> get props => [message];
}

// -- Cubit -------------------------------------------------------------------

class LlmDiagnosisCubit extends Cubit<LlmDiagnosisState> {
  final GetLlmDiagnosisUseCase _useCase;

  LlmDiagnosisCubit(this._useCase) : super(const LlmDiagnosisIdle());

  /// Carga una respuesta ya guardada sin llamar al servidor.
  void loadCached(LlmResponseEntity response) {
    emit(LlmDiagnosisLoaded(response));
  }

  Future<void> consultar({
    required DiagnosisEntity diagnosis,
    required String rol,
    String? userText,
  }) async {
    emit(const LlmDiagnosisLoading());
    final result = await _useCase(
      LlmConsultaParams(diagnosis: diagnosis, rol: rol, userText: userText),
    );
    result.fold(
      (failure) => emit(LlmDiagnosisError(failure.message)),
      (response) => emit(LlmDiagnosisLoaded(response)),
    );
  }

  void reset() => emit(const LlmDiagnosisIdle());
}
