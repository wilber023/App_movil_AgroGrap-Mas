import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../notifications/domain/entities/push_notification_entry_entity.dart';
import '../../../notifications/domain/usecases/get_notification_history_usecase.dart';
import '../../domain/entities/alerta_epidemiologica_entity.dart';

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
/// La alerta que antes venia del endpoint nacional de clustering
/// (`GET /api/v1/alertas`) quedaba desactualizada (no reflejaba lo que el
/// usuario ya veia en la campanita de notificaciones). Ahora se reusa la
/// misma fuente que `NotificationsPage`: el historial local de push
/// recibidas (`NotificationHistoryRepository.getHistory()`, ya ordenado del
/// mas reciente al mas antiguo), tomando solo la mas reciente. Sin
/// notificaciones guardadas -> sin alerta, nunca datos inventados.
class EpidemiologicalAlertCubit extends Cubit<EpidemiologicalAlertState> {
  final GetNotificationHistoryUseCase getNotificationHistoryUseCase;

  EpidemiologicalAlertCubit({
    required this.getNotificationHistoryUseCase,
  }) : super(const EpidemiologicalAlertInitial());

  Future<void> load() async {
    emit(const EpidemiologicalAlertLoading());

    final historyResult = await getNotificationHistoryUseCase(const NoParams());
    final alerta = historyResult.fold(
      (_) => null,
      (items) => items.isEmpty ? null : _toAlerta(items.first),
    );
    emit(EpidemiologicalAlertLoaded(alerta));
  }

  /// El historial no trae nivel de severidad ni el contrato de
  /// `AlertaEpidemiologicaEntity` completo (solo `title`/`body`/`estado`);
  /// se arma la version minima que el banner necesita para mostrarse.
  AlertaEpidemiologicaEntity? _toAlerta(PushNotificationEntryEntity entry) {
    final mensaje = entry.body.trim().isNotEmpty ? entry.body.trim() : entry.title.trim();
    if (mensaje.isEmpty) return null;

    return AlertaEpidemiologicaEntity(
      hayAlerta: true,
      estado: entry.estado?.trim() ?? '',
      mensaje: mensaje,
    );
  }
}
