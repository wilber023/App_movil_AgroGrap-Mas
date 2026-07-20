import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/network/network_info.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../agenda/domain/usecases/generate_agenda_usecase.dart';
import '../../domain/entities/crop_plan_entity.dart';
import '../../domain/entities/crop_practice_location.dart';
import '../../domain/usecases/get_saved_crop_plan_usecase.dart';
import '../../domain/usecases/get_sowing_plan_text_usecase.dart';
import '../../domain/usecases/register_crop_plan_usecase.dart';

// -- Events --
sealed class CultivoEvent extends Equatable {
  const CultivoEvent();
  @override
  List<Object?> get props => [];
}

final class CultivoOverviewRequested extends CultivoEvent {
  const CultivoOverviewRequested();
}

final class CultivoCropRegistered extends CultivoEvent {
  final String cultivoId;
  final DateTime startDate;
  final CropPracticeLocation practiceLocation;
  const CultivoCropRegistered({
    required this.cultivoId,
    required this.startDate,
    required this.practiceLocation,
  });
  @override
  List<Object?> get props => [cultivoId, startDate, practiceLocation];
}

// -- States --
sealed class CultivoState extends Equatable {
  const CultivoState();
  @override
  List<Object?> get props => [];
}

final class CultivoInitial extends CultivoState {
  const CultivoInitial();
}

final class CultivoLoading extends CultivoState {
  const CultivoLoading();
}

final class CultivoLoaded extends CultivoState {
  final CropPlanEntity plan;
  final bool isOffline;
  const CultivoLoaded(this.plan, {this.isOffline = false});
  @override
  List<Object?> get props => [plan, isOffline];
}

final class CultivoRegistering extends CultivoState {
  const CultivoRegistering();
}

final class CultivoFailure extends CultivoState {
  final String message;
  const CultivoFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// -- Bloc --
class CultivoBloc extends Bloc<CultivoEvent, CultivoState> {
  final GetSavedCropPlanUseCase getSavedCropPlanUseCase;
  final RegisterCropPlanUseCase registerCropPlanUseCase;
  final GetSowingPlanTextUseCase getSowingPlanTextUseCase;
  final GenerateAgendaUseCase generateAgendaUseCase;
  final NetworkInfo networkInfo;

  CultivoBloc({
    required this.getSavedCropPlanUseCase,
    required this.registerCropPlanUseCase,
    required this.getSowingPlanTextUseCase,
    required this.generateAgendaUseCase,
    required this.networkInfo,
  }) : super(const CultivoInitial()) {
    on<CultivoOverviewRequested>(_onOverviewRequested);
    on<CultivoCropRegistered>(_onCropRegistered);
  }

  Future<void> _onOverviewRequested(
    CultivoOverviewRequested event,
    Emitter<CultivoState> emit,
  ) async {
    emit(const CultivoLoading());
    final isOffline = !(await networkInfo.isConnected);
    final result = await getSavedCropPlanUseCase(const NoParams());
    result.fold(
      (failure) => emit(CultivoFailure(failure.message)),
      (plan) => emit(CultivoLoaded(plan, isOffline: isOffline)),
    );
  }

  Future<void> _onCropRegistered(
    CultivoCropRegistered event,
    Emitter<CultivoState> emit,
  ) async {
    final cultivoId = event.cultivoId.trim();
    if (cultivoId.isEmpty) {
      emit(const CultivoFailure('Selecciona un cultivo antes de continuar.'));
      return;
    }

    emit(const CultivoRegistering());
    final result = await registerCropPlanUseCase(
      RegisterCropPlanParams(
        cultivoId: cultivoId,
        startDate: event.startDate,
        practiceLocation: event.practiceLocation,
      ),
    );
    result.fold(
      (failure) => emit(CultivoFailure(failure.message)),
      (plan) {
        emit(CultivoLoaded(plan));
        unawaited(_generateSowingPlanAgenda(plan.cropName, event.practiceLocation));
      },
    );
  }

  /// Tras registrar el cultivo de práctica, pide al backend LLM el texto del
  /// plan de siembra y lo envía al mismo endpoint de agenda que ya usa el
  /// diagnóstico (`GenerateAgendaUseCase`) para generar las actividades.
  ///
  /// Se ejecuta en segundo plano, sin bloquear ni alterar el registro del
  /// cultivo (ya completado y emitido arriba): la agenda generada queda
  /// cacheada por `AgendaRepository` y aparece cuando el usuario visite la
  /// pestaña Agenda, igual que tras un diagnóstico. Un fallo aquí no afecta
  /// el estado de `CultivoBloc` ni el resto de la app.
  Future<void> _generateSowingPlanAgenda(
    String cropName,
    CropPracticeLocation practiceLocation,
  ) async {
    final textResult = await getSowingPlanTextUseCase(
      GetSowingPlanTextParams(cropName: cropName, practiceLocation: practiceLocation),
    );
    await textResult.fold(
      (failure) async => _logSowingPlanIssue(
        'No se pudo generar el texto del plan de siembra: ${failure.message}',
      ),
      (texto) async {
        final agendaResult = await generateAgendaUseCase(
          GenerateAgendaParams(
            cultivo: cropName,
            enfermedad: '',
            tratamiento: texto,
            prevencion: '',
          ),
        );
        agendaResult.fold(
          (failure) => _logSowingPlanIssue(
            'No se pudo generar la agenda del plan de siembra: ${failure.message}',
          ),
          (_) {},
        );
      },
    );
  }

  void _logSowingPlanIssue(String message) {
    if (kDebugMode) debugPrint('[Cultivo] $message');
  }
}
