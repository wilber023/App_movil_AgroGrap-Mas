import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';
import '../../../diagnosis/domain/entities/llm_response_entity.dart';
import '../../domain/repositories/aprendiz_diagnosis_repository.dart';
import '../datasources/aprendiz_diagnosis_history_local_datasource.dart';
import '../datasources/aprendiz_diagnosis_local_datasource.dart';

/// El CNN corre siempre localmente vía TFLite (mismo motor que usa el perfil
/// Agrónomo, ver [AprendizDiagnosisLocalDataSource]) — no existe un endpoint
/// remoto real de análisis. El único backend real involucrado en este flujo
/// es el LLM (consultado aparte por `LlmDiagnosisCubit`, reutilizado tal cual).
///
/// El historial vive en SQLite, en una tabla EXCLUSIVA del perfil Aprendiz
/// (ver [AprendizDiagnosisHistoryLocalDataSource]), separada del almacén que
/// usa el perfil Agricultor, y cada registro se etiqueta con el `userId` del
/// usuario autenticado para que nunca se mezclen diagnósticos entre
/// perfiles ni entre distintos usuarios del mismo dispositivo.
class AprendizDiagnosisRepositoryImpl implements AprendizDiagnosisRepository {
  final AprendizDiagnosisLocalDataSource localDataSource;
  final AprendizDiagnosisHistoryLocalDataSource historyLocalDataSource;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AprendizDiagnosisRepositoryImpl({
    required this.localDataSource,
    required this.historyLocalDataSource,
    required this.getCurrentUserUseCase,
  });

  @override
  Future<Either<Failure, DiagnosisEntity>> analyzeCrop({required String imagePath, String? description}) async {
    try {
      final result = await localDataSource.analyzeCropOffline(imagePath: imagePath, description: description);
      final userId = await _currentUserId();
      await historyLocalDataSource.insertDiagnosis(result, userId: userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: 'No se pudo analizar la imagen: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveLlmResponse({
    required String diagnosisId,
    required LlmResponseEntity llmResponse,
  }) async {
    try {
      await historyLocalDataSource.updateLlmResponse(diagnosisId: diagnosisId, llmResponse: llmResponse);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'No se pudo guardar la explicación IA: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DiagnosisEntity>>> getHistory() async {
    try {
      final userId = await _currentUserId();
      if (userId == null) {
        return const Left(AuthFailure(message: 'No hay una sesión activa.'));
      }
      final items = await historyLocalDataSource.getDiagnoses(userId: userId);
      return Right(items);
    } catch (e) {
      return Left(CacheFailure(message: 'No se pudo leer el historial de diagnósticos: $e'));
    }
  }

  Future<String?> _currentUserId() async {
    final result = await getCurrentUserUseCase(const NoParams());
    return result.fold((failure) => null, (user) => user.id.isEmpty ? null : user.id);
  }
}
