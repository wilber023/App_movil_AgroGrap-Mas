import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/notification_preferences_entity.dart';
import '../../domain/usecases/cancel_alert_subscription_usecase.dart';
import '../../domain/usecases/notification_preferences_usecases.dart';
import '../../domain/usecases/subscribe_to_alerts_usecase.dart';

// =============================================================================
// Events
// =============================================================================

sealed class NotificationSubscriptionEvent extends Equatable {
  const NotificationSubscriptionEvent();
  @override
  List<Object?> get props => [];
}

/// Carga la preferencia guardada localmente (estado/cultivos/enabled).
final class NotificationPreferencesRequested extends NotificationSubscriptionEvent {
  const NotificationPreferencesRequested();
}

/// Activa las alertas: obtiene el token FCM y llama a POST /suscripciones.
final class NotificationSubscribeRequested extends NotificationSubscriptionEvent {
  final String estado;
  final List<String> cultivos;
  const NotificationSubscribeRequested({required this.estado, this.cultivos = const []});
  @override
  List<Object?> get props => [estado, cultivos];
}

/// Desactiva las alertas (DELETE /suscripciones/yo).
final class NotificationUnsubscribeRequested extends NotificationSubscriptionEvent {
  const NotificationUnsubscribeRequested();
}

// =============================================================================
// States
// =============================================================================

sealed class NotificationSubscriptionState extends Equatable {
  const NotificationSubscriptionState();
  @override
  List<Object?> get props => [];
}

final class NotificationSubscriptionInitial extends NotificationSubscriptionState {
  const NotificationSubscriptionInitial();
}

final class NotificationSubscriptionLoading extends NotificationSubscriptionState {
  const NotificationSubscriptionLoading();
}

final class NotificationSubscriptionLoaded extends NotificationSubscriptionState {
  final NotificationPreferencesEntity preferences;
  const NotificationSubscriptionLoaded({required this.preferences});
  @override
  List<Object?> get props => [preferences];
}

final class NotificationSubscriptionSaving extends NotificationSubscriptionState {
  final NotificationPreferencesEntity preferences;
  const NotificationSubscriptionSaving({required this.preferences});
  @override
  List<Object?> get props => [preferences];
}

/// [message] siempre es un texto seguro para mostrar al usuario -- nunca
/// contiene detalle crudo del backend (ver NotificationRemoteDataSource).
final class NotificationSubscriptionFailure extends NotificationSubscriptionState {
  final String message;
  final NotificationPreferencesEntity preferences;
  const NotificationSubscriptionFailure({required this.message, required this.preferences});
  @override
  List<Object?> get props => [message, preferences];
}

// =============================================================================
// Bloc
// =============================================================================

class NotificationSubscriptionBloc
    extends Bloc<NotificationSubscriptionEvent, NotificationSubscriptionState> {
  final SubscribeToAlertsUseCase _subscribeUseCase;
  final CancelAlertSubscriptionUseCase _cancelUseCase;
  final GetNotificationPreferencesUseCase _getPreferencesUseCase;
  final SaveNotificationPreferencesUseCase _savePreferencesUseCase;

  NotificationSubscriptionBloc({
    required SubscribeToAlertsUseCase subscribeUseCase,
    required CancelAlertSubscriptionUseCase cancelUseCase,
    required GetNotificationPreferencesUseCase getPreferencesUseCase,
    required SaveNotificationPreferencesUseCase savePreferencesUseCase,
  })  : _subscribeUseCase = subscribeUseCase,
        _cancelUseCase = cancelUseCase,
        _getPreferencesUseCase = getPreferencesUseCase,
        _savePreferencesUseCase = savePreferencesUseCase,
        super(const NotificationSubscriptionInitial()) {
    on<NotificationPreferencesRequested>(_onPreferencesRequested);
    on<NotificationSubscribeRequested>(_onSubscribeRequested);
    on<NotificationUnsubscribeRequested>(_onUnsubscribeRequested);
  }

  NotificationPreferencesEntity _prefsOf(NotificationSubscriptionState state) => switch (state) {
        NotificationSubscriptionLoaded(:final preferences) => preferences,
        NotificationSubscriptionSaving(:final preferences) => preferences,
        NotificationSubscriptionFailure(:final preferences) => preferences,
        _ => NotificationPreferencesEntity.empty,
      };

  Future<void> _onPreferencesRequested(
    NotificationPreferencesRequested event,
    Emitter<NotificationSubscriptionState> emit,
  ) async {
    emit(const NotificationSubscriptionLoading());
    final result = await _getPreferencesUseCase(const NoParams());
    result.fold(
      (f) => emit(NotificationSubscriptionLoaded(preferences: NotificationPreferencesEntity.empty)),
      (prefs) => emit(NotificationSubscriptionLoaded(preferences: prefs)),
    );
  }

  Future<void> _onSubscribeRequested(
    NotificationSubscribeRequested event,
    Emitter<NotificationSubscriptionState> emit,
  ) async {
    final current = _prefsOf(state);
    final newPrefs = NotificationPreferencesEntity(
      enabled: true,
      estado: event.estado,
      cultivos: event.cultivos,
    );
    emit(NotificationSubscriptionSaving(preferences: newPrefs));

    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[Notifications] getToken falló: $e');
    }

    if (fcmToken == null) {
      emit(NotificationSubscriptionFailure(
        message: 'No se pudo obtener el identificador de este dispositivo. Verifica los permisos de notificación e intenta de nuevo.',
        preferences: current,
      ));
      return;
    }

    final result = await _subscribeUseCase(SubscribeParams(
      fcmToken: fcmToken,
      estado: event.estado,
      cultivos: event.cultivos,
    ));

    final failed = result.fold(
      (f) {
        emit(NotificationSubscriptionFailure(message: f.message, preferences: current));
        return true;
      },
      (_) => false,
    );
    if (failed) return;

    await _savePreferencesUseCase(newPrefs);
    emit(NotificationSubscriptionLoaded(preferences: newPrefs));
  }

  Future<void> _onUnsubscribeRequested(
    NotificationUnsubscribeRequested event,
    Emitter<NotificationSubscriptionState> emit,
  ) async {
    final current = _prefsOf(state);
    final disabledPrefs = NotificationPreferencesEntity(
      enabled: false,
      estado: current.estado,
      cultivos: current.cultivos,
    );
    emit(NotificationSubscriptionSaving(preferences: disabledPrefs));

    final result = await _cancelUseCase(const NoParams());
    final failed = result.fold(
      (f) {
        emit(NotificationSubscriptionFailure(message: f.message, preferences: current));
        return true;
      },
      (_) => false,
    );
    if (failed) return;

    await _savePreferencesUseCase(disabledPrefs);
    emit(NotificationSubscriptionLoaded(preferences: disabledPrefs));
  }
}
