import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/parcel_entity.dart';
import '../../domain/repositories/parcel_repository.dart';
import '../../domain/usecases/add_parcel_usecase.dart';
import '../../domain/usecases/delete_parcel_usecase.dart';
import '../../domain/usecases/get_parcels_usecase.dart';

// =============================================================================
// Events
// =============================================================================

sealed class ParcelEvent extends Equatable {
  const ParcelEvent();
  @override
  List<Object?> get props => [];
}

final class ParcelLoadRequested extends ParcelEvent {
  const ParcelLoadRequested();
}

final class ParcelRefreshRequested extends ParcelEvent {
  const ParcelRefreshRequested();
}

final class ParcelAddRequested extends ParcelEvent {
  final AddParcelParams params;
  const ParcelAddRequested({required this.params});
  @override
  List<Object?> get props => [params];
}

final class ParcelDeleteRequested extends ParcelEvent {
  final String seleccionId;
  const ParcelDeleteRequested({required this.seleccionId});
  @override
  List<Object?> get props => [seleccionId];
}

// =============================================================================
// States
// =============================================================================

sealed class ParcelState extends Equatable {
  const ParcelState();
  @override
  List<Object?> get props => [];
}

final class ParcelInitial extends ParcelState {
  const ParcelInitial();
}

final class ParcelLoading extends ParcelState {
  const ParcelLoading();
}

final class ParcelLoaded extends ParcelState {
  final List<ParcelEntity> parcels;
  const ParcelLoaded({required this.parcels});
  @override
  List<Object?> get props => [parcels];
}

final class ParcelFailure extends ParcelState {
  final String message;
  const ParcelFailure({required this.message});
  @override
  List<Object?> get props => [message];
}

final class ParcelSaving extends ParcelState {
  const ParcelSaving();
}

final class ParcelSaved extends ParcelState {
  final ParcelEntity parcel;
  const ParcelSaved({required this.parcel});
  @override
  List<Object?> get props => [parcel];
}

final class ParcelDeleted extends ParcelState {
  const ParcelDeleted();
}

// =============================================================================
// Bloc
// =============================================================================

class ParcelBloc extends Bloc<ParcelEvent, ParcelState> {
  final GetParcelsUseCase _getParcelsUseCase;
  final AddParcelUseCase _addParcelUseCase;
  final DeleteParcelUseCase _deleteParcelUseCase;

  ParcelBloc({
    required GetParcelsUseCase getParcelsUseCase,
    required AddParcelUseCase addParcelUseCase,
    required DeleteParcelUseCase deleteParcelUseCase,
  })  : _getParcelsUseCase = getParcelsUseCase,
        _addParcelUseCase = addParcelUseCase,
        _deleteParcelUseCase = deleteParcelUseCase,
        super(const ParcelInitial()) {
    on<ParcelLoadRequested>(_onLoad);
    on<ParcelRefreshRequested>(_onRefresh);
    on<ParcelAddRequested>(_onAdd);
    on<ParcelDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(ParcelLoadRequested event, Emitter<ParcelState> emit) async {
    emit(const ParcelLoading());
    final result = await _getParcelsUseCase(const NoParams());
    result.fold(
      (f) => emit(ParcelFailure(message: f.message)),
      (p) => emit(ParcelLoaded(parcels: p)),
    );
  }

  Future<void> _onRefresh(ParcelRefreshRequested event, Emitter<ParcelState> emit) async {
    final result = await _getParcelsUseCase(const NoParams());
    result.fold(
      (f) => emit(ParcelFailure(message: f.message)),
      (p) => emit(ParcelLoaded(parcels: p)),
    );
  }

  Future<void> _onAdd(ParcelAddRequested event, Emitter<ParcelState> emit) async {
    emit(const ParcelSaving());
    final result = await _addParcelUseCase(event.params);
    result.fold(
      (f) => emit(ParcelFailure(message: f.message)),
      (parcel) => emit(ParcelSaved(parcel: parcel)),
    );
  }

  Future<void> _onDelete(ParcelDeleteRequested event, Emitter<ParcelState> emit) async {
    final result = await _deleteParcelUseCase(
      DeleteParcelParams(seleccionId: event.seleccionId),
    );
    result.fold(
      (f) => emit(ParcelFailure(message: f.message)),
      (_) => emit(const ParcelDeleted()),
    );
  }
}
