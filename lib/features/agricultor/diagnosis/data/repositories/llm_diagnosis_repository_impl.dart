// =============================================================================
// AgroGraph-MAS — Implementación repositorio LLM
// =============================================================================

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/network/network_info.dart';
import '../../domain/entities/diagnosis_entity.dart';
import '../../domain/entities/llm_response_entity.dart';
import '../../domain/repositories/llm_diagnosis_repository.dart';
import '../datasources/llm_diagnosis_datasource.dart';

class LlmDiagnosisRepositoryImpl implements LlmDiagnosisRepository {
  final LlmDiagnosisDataSource _dataSource;
  final NetworkInfo _networkInfo;

  LlmDiagnosisRepositoryImpl({
    required LlmDiagnosisDataSource dataSource,
    required NetworkInfo networkInfo,
  })  : _dataSource = dataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, LlmResponseEntity>> consultar({
    required DiagnosisEntity diagnosis,
    String? userText,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await _dataSource.consultar(
        diagnosis: diagnosis,
        userText: userText,
      );
      return Right(result);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        return const Left(
          AuthFailure(message: 'Sesión expirada. Inicia sesión nuevamente.'),
        );
      }
      if (code == 503) {
        return const Left(
          ServerFailure(
            message: 'El asistente IA no está disponible ahora. Intenta más tarde.',
            statusCode: 503,
          ),
        );
      }
      if (code == 504) {
        return const Left(
          ServerFailure(
            message: 'La consulta tardó demasiado. Intenta de nuevo.',
            statusCode: 504,
          ),
        );
      }
      final detail = e.response?.data is Map
          ? (e.response!.data as Map)['detail'] as String?
          : null;
      return Left(
        ServerFailure(message: detail ?? e.message ?? 'Error al contactar el asistente.'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
