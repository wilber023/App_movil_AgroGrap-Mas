// =============================================================================
// AgroGraph-MAS — Contrato repositorio LLM
// =============================================================================

import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../entities/diagnosis_entity.dart';
import '../entities/llm_response_entity.dart';

abstract class LlmDiagnosisRepository {
  Future<Either<Failure, LlmResponseEntity>> consultar({
    required DiagnosisEntity diagnosis,
    required String rol,
    String? userText,
  });
}
