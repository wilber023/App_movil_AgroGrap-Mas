import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../agricultor/diagnosis/domain/entities/llm_response_entity.dart';
import '../repositories/aprendiz_diagnosis_repository.dart';

class SaveDiagnosisLlmResponseParams {
  final String diagnosisId;
  final LlmResponseEntity llmResponse;
  const SaveDiagnosisLlmResponseParams({required this.diagnosisId, required this.llmResponse});
}

class SaveDiagnosisLlmResponseUseCase implements UseCase<void, SaveDiagnosisLlmResponseParams> {
  final AprendizDiagnosisRepository repository;

  SaveDiagnosisLlmResponseUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveDiagnosisLlmResponseParams params) {
    return repository.saveLlmResponse(diagnosisId: params.diagnosisId, llmResponse: params.llmResponse);
  }
}
