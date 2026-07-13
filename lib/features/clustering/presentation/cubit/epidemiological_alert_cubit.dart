import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../notifications/domain/usecases/notification_preferences_usecases.dart';
import '../../domain/entities/alerta_epidemiologica_entity.dart';
import '../../domain/usecases/get_alerta_usecase.dart';

abstract class EpidemiologicalAlertState extends Equatable {
  const EpidemiologicalAlertState();

  @override
  List<Object?> get props => [];
}

class EpidemiologicalAlertInitial extends EpidemiologicalAlertState {
  const EpidemiologicalAlertInitial();
}

class EpidemiologicalAlertLoading extends EpidemiologicalAlertState {
  const EpidemiologicalAlertLoading();
}

/// `alerta` es `null` cuando no hay alerta activa para el estado del
/// usuario (`hay_alerta: false`) o cuando la consulta falló -- en ambos
/// casos el banner simplemente no se muestra, nunca se inventa contenido.
class EpidemiologicalAlertLoaded extends EpidemiologicalAlertState {
  final AlertaEpidemiologicaEntity? alerta;
  const EpidemiologicalAlertLoaded(this.alerta);

  @override
  List<Object?> get props => [alerta];
}

/// Resuelve la alerta epidemiológica para el Home del usuario.
///
/// El "estado" del usuario no tiene una fuente dedicada en la app -- se
/// reusa `NotificationPreferencesEntity.estado`, ya capturado en Ajustes >
/// Notificaciones para este mismo propósito (alertas por estado). Si el
/// usuario nunca lo configuró, se consulta la alerta nacional (`estado:
/// null`), comportamiento explícitamente soportado por el backend.
class EpidemiologicalAlertCubit extends Cubit<EpidemiologicalAlertState> {
  final GetAlertaUseCase getAlertaUseCase;
  final GetNotificationPreferencesUseCase getNotificationPreferencesUseCase;

  EpidemiologicalAlertCubit({
    required this.getAlertaUseCase,
    required this.getNotificationPreferencesUseCase,
  }) : super(const EpidemiologicalAlertInitial());

  Future<void> load() async {
    emit(const EpidemiologicalAlertLoading());

    final prefsResult = await getNotificationPreferencesUseCase(const NoParams());
    final estado = prefsResult.fold(
      (_) => null,
      (prefs) => prefs.estado.trim().isNotEmpty ? prefs.estado.trim() : null,
    );

    final alertaResult = await getAlertaUseCase(GetAlertaParams(estado: estado));
    alertaResult.fold(
      (_) => emit(const EpidemiologicalAlertLoaded(null)),
      (alerta) => emit(EpidemiologicalAlertLoaded(alerta.hayAlerta ? alerta : null)),
    );
  }
}
