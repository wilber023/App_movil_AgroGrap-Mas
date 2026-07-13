import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/estado_resumen_entity.dart';
import '../../domain/usecases/get_mapa_campanias_usecase.dart';

abstract class EpidemiologicalMapState extends Equatable {
  const EpidemiologicalMapState();

  @override
  List<Object?> get props => [];
}

class EpidemiologicalMapInitial extends EpidemiologicalMapState {
  const EpidemiologicalMapInitial();
}

class EpidemiologicalMapLoading extends EpidemiologicalMapState {
  const EpidemiologicalMapLoading();
}

class EpidemiologicalMapLoaded extends EpidemiologicalMapState {
  final MapaCampaniasEntity mapa;
  const EpidemiologicalMapLoaded(this.mapa);

  @override
  List<Object?> get props => [mapa];
}

class EpidemiologicalMapError extends EpidemiologicalMapState {
  final String message;
  const EpidemiologicalMapError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Carga el mapa epidemiológico completo (`GET /clustering/mapa-campanias`)
/// bajo demanda -- una sola llamada al abrir la pantalla, sin polling.
class EpidemiologicalMapCubit extends Cubit<EpidemiologicalMapState> {
  final GetMapaCampaniasUseCase getMapaCampaniasUseCase;

  EpidemiologicalMapCubit({required this.getMapaCampaniasUseCase})
      : super(const EpidemiologicalMapInitial());

  Future<void> load() async {
    emit(const EpidemiologicalMapLoading());
    final result = await getMapaCampaniasUseCase(const NoParams());
    result.fold(
      (failure) => emit(EpidemiologicalMapError(failure.message)),
      (mapa) => emit(EpidemiologicalMapLoaded(mapa)),
    );
  }
}
