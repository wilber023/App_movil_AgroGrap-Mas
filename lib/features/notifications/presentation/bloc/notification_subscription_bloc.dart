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
  final Future<String?> Function() _getFcmToken;

  NotificationSubscriptionBloc({
    required SubscribeToAlertsUseCase subscribeUseCase,
    required CancelAlertSubscriptionUseCase cancelUseCase,
    required GetNotificationPreferencesUseCase getPreferencesUseCase,
    required SaveNotificationPreferencesUseCase savePreferencesUseCase,
    // Inyectable solo para tests (evita depender del plugin real de
    // Firebase, no disponible en flutter_test) -- en producción siempre usa
    // el default real.
    Future<String?> Function()? getFcmToken,
  })  : _subscribeUseCase = subscribeUseCase,
        _cancelUseCase = cancelUseCase,
        _getPreferencesUseCase = getPreferencesUseCase,
        _savePreferencesUseCase = savePreferencesUseCase,
        _getFcmToken = getFcmToken ?? FirebaseMessaging.instance.getToken,
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

  // ---------------------------------------------------------------------------
  // El guardado LOCAL de estado/cultivos (lo único que alimenta el banner de
  // alerta epidemiológica de Inicio, feature de clustering) es independiente
  // de la suscripción push remota (`POST/DELETE /suscripciones` contra
  // `3.218.172.128:8100`, un microservicio externo que puede estar caído o
  // lento). Por eso aquí el guardado local SIEMPRE se completa y se confirma
  // primero -- la llamada remota se intenta después, sin que su resultado
  // (éxito, error o timeout de hasta 15 s) bloquee ni revierta esa
  // confirmación. Si la llamada remota no se pudo confirmar,
  // `pushSyncPending` queda en `true` (guardado localmente también) para no
  // perder esa información, sin mostrarle un error al usuario por algo que
  // sí se guardó correctamente.
  // ---------------------------------------------------------------------------

  Future<void> _onSubscribeRequested(
    NotificationSubscribeRequested event,
    Emitter<NotificationSubscriptionState> emit,
  ) async {
    final newPrefs = NotificationPreferencesEntity(
      enabled: true,
      estado: event.estado,
      cultivos: event.cultivos,
      pushSyncPending: true,
    );
    emit(NotificationSubscriptionSaving(preferences: newPrefs));

    final saveResult = await _savePreferencesUseCase(newPrefs);
    final saveFailed = saveResult.fold(
      (f) {
        emit(NotificationSubscriptionFailure(message: f.message, preferences: _prefsOf(state)));
        return true;
      },
      (_) => false,
    );
    if (saveFailed) return;

    // Confirmación inmediata: el guardado local ya se completó.
    emit(NotificationSubscriptionLoaded(preferences: newPrefs));

    // Suscripción push remota, en segundo plano -- no bloquea lo anterior.
    String? fcmToken;
    try {
      fcmToken = await _getFcmToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[Notifications] getToken falló: $e');
    }
    if (fcmToken == null) {
      if (kDebugMode) {
        debugPrint('[Notifications] Sin token FCM: suscripción push remota omitida (queda pendiente).');
      }
      return;
    }

    final result = await _subscribeUseCase(SubscribeParams(
      fcmToken: fcmToken,
      estado: event.estado,
      cultivos: event.cultivos,
    ));
    await result.fold(
      (f) async {
        if (kDebugMode) debugPrint('[Notifications] Suscripción push remota falló: ${f.message}');
      },
      (_) async {
        final syncedPrefs = newPrefs.copyWith(pushSyncPending: false);
        await _savePreferencesUseCase(syncedPrefs);
        if (!isClosed && _prefsOf(state) == newPrefs) {
          emit(NotificationSubscriptionLoaded(preferences: syncedPrefs));
        }
      },
    );
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
      pushSyncPending: true,
    );
    emit(NotificationSubscriptionSaving(preferences: disabledPrefs));

    final saveResult = await _savePreferencesUseCase(disabledPrefs);
    final saveFailed = saveResult.fold(
      (f) {
        emit(NotificationSubscriptionFailure(message: f.message, preferences: current));
        return true;
      },
      (_) => false,
    );
    if (saveFailed) return;

    // Confirmación inmediata: el guardado local ya se completó.
    emit(NotificationSubscriptionLoaded(preferences: disabledPrefs));

    // Cancelación remota, en segundo plano -- no bloquea lo anterior.
    final result = await _cancelUseCase(const NoParams());
    await result.fold(
      (f) async {
        if (kDebugMode) debugPrint('[Notifications] Cancelación push remota falló: ${f.message}');
      },
      (_) async {
        final syncedPrefs = disabledPrefs.copyWith(pushSyncPending: false);
        await _savePreferencesUseCase(syncedPrefs);
        if (!isClosed && _prefsOf(state) == disabledPrefs) {
          emit(NotificationSubscriptionLoaded(preferences: syncedPrefs));
        }
      },
    );
  }
}
