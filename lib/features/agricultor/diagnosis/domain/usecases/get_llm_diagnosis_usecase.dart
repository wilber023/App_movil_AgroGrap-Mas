// =============================================================================
// AgroGraph-MAS — UseCase: GetLlmDiagnosisUseCase
// =============================================================================

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/diagnosis_entity.dart';
import '../entities/llm_response_entity.dart';
import '../repositories/llm_diagnosis_repository.dart';

class LlmConsultaParams extends Equatable {
  final DiagnosisEntity diagnosis;
  final String? userText;

  const LlmConsultaParams({required this.diagnosis, this.userText});

  @override
  List<Object?> get props => [diagnosis, userText];
}

class GetLlmDiagnosisUseCase
    implements UseCase<LlmResponseEntity, LlmConsultaParams> {
  final LlmDiagnosisRepository _repository;

  GetLlmDiagnosisUseCase(this._repository);

  @override
  Future<Either<Failure, LlmResponseEntity>> call(LlmConsultaParams params) {
    return _repository.consultar(
      diagnosis: params.diagnosis,
      userText: params.userText,
    );
  }
}
