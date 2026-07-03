import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';
import '../../../diagnosis/domain/entities/llm_response_entity.dart';

abstract class AprendizDiagnosisRepository {
  Future<Either<Failure, DiagnosisEntity>> analyzeCrop({required String imagePath, String? description});

  /// Historial de diagnósticos del aprendiz (misma fuente local que usa el
  /// perfil Agrónomo: Hive box `diagnosisBox`), ordenado del más reciente al más antiguo.
  Future<Either<Failure, List<DiagnosisEntity>>> getHistory();

  /// Persiste la respuesta del LLM en el registro del diagnóstico indicado,
  /// para que quede disponible en consultas futuras del historial.
  Future<Either<Failure, void>> saveLlmResponse({
    required String diagnosisId,
    required LlmResponseEntity llmResponse,
  });
}
