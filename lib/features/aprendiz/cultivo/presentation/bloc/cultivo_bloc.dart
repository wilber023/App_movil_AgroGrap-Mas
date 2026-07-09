import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/network/network_info.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/crop_plan_entity.dart';
import '../../domain/entities/crop_practice_location.dart';
import '../../domain/usecases/get_saved_crop_plan_usecase.dart';
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
  final String cropName;
  final DateTime startDate;
  final CropPracticeLocation practiceLocation;
  const CultivoCropRegistered({
    required this.cropName,
    required this.startDate,
    required this.practiceLocation,
  });
  @override
  List<Object?> get props => [cropName, startDate, practiceLocation];
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
  final NetworkInfo networkInfo;

  CultivoBloc({
    required this.getSavedCropPlanUseCase,
    required this.registerCropPlanUseCase,
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
    final cropName = event.cropName.trim();
    if (cropName.isEmpty) {
      emit(const CultivoFailure('Selecciona un cultivo antes de continuar.'));
      return;
    }

    emit(const CultivoRegistering());
    final result = await registerCropPlanUseCase(
      RegisterCropPlanParams(
        cropName: cropName,
        startDate: event.startDate,
        practiceLocation: event.practiceLocation,
      ),
    );
    result.fold(
      (failure) => emit(CultivoFailure(failure.message)),
      (plan) => emit(CultivoLoaded(plan)),
    );
  }
}
