// =============================================================================
// AgroGraph-MAS — OfflineKnowledgeCubit
// Estado de presentación del fallback offline de diagnóstico.
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/diagnosis_detail.dart';
import '../../domain/usecases/get_offline_diagnosis_detail_usecase.dart';

// -- States ------------------------------------------------------------------

sealed class OfflineKnowledgeState extends Equatable {
  const OfflineKnowledgeState();
  @override
  List<Object?> get props => [];
}

final class OfflineKnowledgeIdle extends OfflineKnowledgeState {
  const OfflineKnowledgeIdle();
}

final class OfflineKnowledgeLoading extends OfflineKnowledgeState {
  const OfflineKnowledgeLoading();
}

final class OfflineKnowledgeLoaded extends OfflineKnowledgeState {
  final DiagnosisDetail detail;
  const OfflineKnowledgeLoaded(this.detail);
  @override
  List<Object?> get props => [detail];
}

final class OfflineKnowledgeError extends OfflineKnowledgeState {
  final String message;
  const OfflineKnowledgeError(this.message);
  @override
  List<Object?> get props => [message];
}

// -- Cubit -------------------------------------------------------------------

class OfflineKnowledgeCubit extends Cubit<OfflineKnowledgeState> {
  final GetOfflineDiagnosisDetailUseCase _useCase;

  OfflineKnowledgeCubit(this._useCase) : super(const OfflineKnowledgeIdle());

  Future<void> load({
    required String cultivo,
    required String enfermedadId,
    required double confianzaCnn,
  }) async {
    emit(const OfflineKnowledgeLoading());
    try {
      final detail = await _useCase(
        cultivo: cultivo,
        enfermedadId: enfermedadId,
        confianzaCnn: confianzaCnn,
      );
      emit(OfflineKnowledgeLoaded(detail));
    } catch (e) {
      emit(OfflineKnowledgeError(e.toString()));
    }
  }

  void reset() => emit(const OfflineKnowledgeIdle());
}
