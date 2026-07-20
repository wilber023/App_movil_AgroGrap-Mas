// =============================================================================
// AgroGraph-MAS — LlmDiagnosisCubit
// Estado del enriquecimiento IA en la pantalla de resultado.
// =============================================================================

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../clustering/domain/usecases/enviar_reporte_diagnostico_usecase.dart';
import '../../../parcels/domain/usecases/get_parcel_region_local_usecase.dart';
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
  final EnviarReporteDiagnosticoUseCase _enviarReporteUseCase;
  final GetParcelRegionLocalUseCase _getParcelRegionLocalUseCase;

  LlmDiagnosisCubit(
    this._useCase, {
    required EnviarReporteDiagnosticoUseCase enviarReporteUseCase,
    required GetParcelRegionLocalUseCase getParcelRegionLocalUseCase,
  })  : _enviarReporteUseCase = enviarReporteUseCase,
        _getParcelRegionLocalUseCase = getParcelRegionLocalUseCase,
        super(const LlmDiagnosisIdle());

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
      (response) {
        emit(LlmDiagnosisLoaded(response));
        // Fire-and-forget: alimenta el sistema de Clustering. Nunca debe
        // bloquear la UI ni afectar el resultado del diagnóstico ya emitido.
        unawaited(_reportarDiagnostico(diagnosis));
      },
    );
  }

  Future<void> _reportarDiagnostico(DiagnosisEntity diagnosis) async {
    try {
      final cultivo = diagnosis.cropName.trim();
      final plaga = diagnosis.diseaseName.trim();
      final estado = (await _resolverRegion(
        parcelId: diagnosis.parcelId,
        cropName: diagnosis.cropName,
      ))
          .trim();

      if (cultivo.isEmpty || plaga.isEmpty || estado.isEmpty) {
        debugPrint(
          '[ClusteringReporte] omitido -- falta un campo '
          '(cultivo="$cultivo", plaga="$plaga", estado="$estado")',
        );
        return;
      }

      await _enviarReporteUseCase(
        EnviarReporteDiagnosticoParams(cultivo: cultivo, plaga: plaga, estado: estado),
      );
    } catch (e) {
      debugPrint('[ClusteringReporte] error al preparar el envío, descartado: $e');
    }
  }

  /// Región/Comunidad de la parcela del diagnóstico, leída de la caché
  /// local (`GetParcelRegionLocalUseCase` → `ParcelEntity.region`) — nunca
  /// consulta el microservicio de Cultivos. Si el diagnóstico no trae un
  /// `parcelId` (diagnóstico genérico, no iniciado desde una parcela),
  /// se resuelve por el cultivo cacheado que coincide o, si el usuario solo
  /// tiene una parcela registrada, por esa única parcela.
  Future<String> _resolverRegion({required String? parcelId, required String cropName}) async {
    return await _getParcelRegionLocalUseCase(parcelId: parcelId, cropName: cropName) ?? '';
  }

  void reset() => emit(const LlmDiagnosisIdle());
}
