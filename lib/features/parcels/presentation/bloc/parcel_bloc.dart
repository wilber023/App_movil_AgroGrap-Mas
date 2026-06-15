import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/parcel_entity.dart';
import '../../domain/usecases/get_parcels_usecase.dart';

// -- Events --
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

// -- States --
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

// -- Bloc --
class ParcelBloc extends Bloc<ParcelEvent, ParcelState> {
  final GetParcelsUseCase _getParcelsUseCase;

  ParcelBloc({required GetParcelsUseCase getParcelsUseCase})
      : _getParcelsUseCase = getParcelsUseCase,
        super(const ParcelInitial()) {
    on<ParcelLoadRequested>(_onLoad);
    on<ParcelRefreshRequested>(_onRefresh);
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
}
