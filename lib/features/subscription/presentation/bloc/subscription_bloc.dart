import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/usecases/cancel_subscription_usecase.dart';
import '../../domain/usecases/get_subscription_status_usecase.dart';
import '../../domain/usecases/subscribe_usecase.dart';

// =============================================================================
// Events
// =============================================================================

sealed class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

/// Carga el estado actual de la suscripcion (GET /subscription).
final class SubscriptionStatusRequested extends SubscriptionEvent {
  const SubscriptionStatusRequested();
}

/// Inicia una nueva suscripcion para el plan indicado (POST /subscribe).
final class SubscriptionSubscribeRequested extends SubscriptionEvent {
  final String plan;
  const SubscriptionSubscribeRequested({required this.plan});
  @override
  List<Object?> get props => [plan];
}

/// Se dispara al volver del navegador de PayPal (AppLifecycleState.resumed):
/// hace polling de GET /subscription hasta 5 veces / 3s de espera.
final class SubscriptionApprovalPollRequested extends SubscriptionEvent {
  const SubscriptionApprovalPollRequested();
}

/// Cancela la suscripcion activa (POST /cancel).
final class SubscriptionCancelRequested extends SubscriptionEvent {
  const SubscriptionCancelRequested();
}

// =============================================================================
// States
// =============================================================================

sealed class SubscriptionState extends Equatable {
  const SubscriptionState();
  @override
  List<Object?> get props => [];
}

final class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

final class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

/// `subscription == null` significa plan gratuito / sin suscripcion.
final class SubscriptionLoaded extends SubscriptionState {
  final SubscriptionEntity? subscription;
  const SubscriptionLoaded({this.subscription});
  @override
  List<Object?> get props => [subscription];
}

final class SubscriptionSubscribing extends SubscriptionState {
  final String plan;
  final SubscriptionEntity? subscription;
  const SubscriptionSubscribing({required this.plan, this.subscription});
  @override
  List<Object?> get props => [plan, subscription];
}

/// La suscripcion fue creada en PayPal: la UI debe abrir [approveUrl] en el
/// navegador externo (url_launcher) y esperar a que el usuario regrese.
final class SubscriptionApprovalUrlReady extends SubscriptionState {
  final String approveUrl;
  final SubscriptionEntity? subscription;
  const SubscriptionApprovalUrlReady({required this.approveUrl, this.subscription});
  @override
  List<Object?> get props => [approveUrl, subscription];
}

final class SubscriptionPolling extends SubscriptionState {
  final SubscriptionEntity? subscription;
  const SubscriptionPolling({this.subscription});
  @override
  List<Object?> get props => [subscription];
}

/// PayPal puede tardar mas de 15s en confirmar el pago via webhook.
final class SubscriptionPollingTimedOut extends SubscriptionState {
  final SubscriptionEntity? subscription;
  const SubscriptionPollingTimedOut({this.subscription});
  @override
  List<Object?> get props => [subscription];
}

final class SubscriptionCancelling extends SubscriptionState {
  final SubscriptionEntity? subscription;
  const SubscriptionCancelling({this.subscription});
  @override
  List<Object?> get props => [subscription];
}

/// [message] siempre es un texto seguro para mostrar al usuario -- nunca
/// contiene detalle crudo del backend/PayPal (ver SubscriptionRemoteDataSource).
final class SubscriptionActionFailure extends SubscriptionState {
  final String message;
  final SubscriptionEntity? subscription;
  const SubscriptionActionFailure({required this.message, this.subscription});
  @override
  List<Object?> get props => [message, subscription];
}

/// Fallo especifico de la carga INICIAL (GET /subscription al abrir la
/// pantalla): a diferencia de [SubscriptionActionFailure], aqui no hay
/// ningun dato previo que mostrar, asi que la UI debe presentar un estado
/// de error dedicado (con reintento) en vez de asumir "plan gratuito".
final class SubscriptionLoadFailure extends SubscriptionState {
  final String message;
  const SubscriptionLoadFailure({required this.message});
  @override
  List<Object?> get props => [message];
}

// =============================================================================
// Bloc
// =============================================================================

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscribeUseCase _subscribeUseCase;
  final GetSubscriptionStatusUseCase _getSubscriptionStatusUseCase;
  final CancelSubscriptionUseCase _cancelSubscriptionUseCase;

  static const _pollAttempts = 5;
  static const _pollDelay = Duration(seconds: 3);

  SubscriptionBloc({
    required SubscribeUseCase subscribeUseCase,
    required GetSubscriptionStatusUseCase getSubscriptionStatusUseCase,
    required CancelSubscriptionUseCase cancelSubscriptionUseCase,
  })  : _subscribeUseCase = subscribeUseCase,
        _getSubscriptionStatusUseCase = getSubscriptionStatusUseCase,
        _cancelSubscriptionUseCase = cancelSubscriptionUseCase,
        super(const SubscriptionInitial()) {
    on<SubscriptionStatusRequested>(_onStatusRequested);
    on<SubscriptionSubscribeRequested>(_onSubscribeRequested);
    on<SubscriptionApprovalPollRequested>(_onApprovalPollRequested);
    on<SubscriptionCancelRequested>(_onCancelRequested);
  }

  SubscriptionEntity? _subscriptionOf(SubscriptionState state) => switch (state) {
        SubscriptionLoaded(:final subscription) => subscription,
        SubscriptionSubscribing(:final subscription) => subscription,
        SubscriptionApprovalUrlReady(:final subscription) => subscription,
        SubscriptionPolling(:final subscription) => subscription,
        SubscriptionPollingTimedOut(:final subscription) => subscription,
        SubscriptionCancelling(:final subscription) => subscription,
        SubscriptionActionFailure(:final subscription) => subscription,
        _ => null,
      };

  Future<void> _onStatusRequested(
    SubscriptionStatusRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    if (kDebugMode) {
      debugPrint('[SUB-TRACE] 2) SubscriptionBloc._onStatusRequested -- entra al bloc');
    }
    emit(const SubscriptionLoading());
    if (kDebugMode) {
      debugPrint('[SUB-TRACE] 3) SubscriptionBloc -- llamando a GetSubscriptionStatusUseCase');
    }
    final result = await _getSubscriptionStatusUseCase(const NoParams());
    result.fold(
      (f) {
        if (kDebugMode) {
          debugPrint(
            '[SUB-TRACE] 11) SubscriptionBloc -- UseCase devolvio Failure '
            'tipo=${f.runtimeType} statusCode=${f.statusCode} message="${f.message}" '
            '-> emit(SubscriptionLoadFailure)',
          );
        }
        emit(SubscriptionLoadFailure(message: f.message));
      },
      (sub) {
        if (kDebugMode) {
          debugPrint(
            '[SUB-TRACE] 11) SubscriptionBloc -- UseCase devolvio Right(subscription='
            '${sub == null ? "null (sin suscripcion)" : sub.status}) -> emit(SubscriptionLoaded)',
          );
        }
        emit(SubscriptionLoaded(subscription: sub));
      },
    );
  }

  Future<void> _onSubscribeRequested(
    SubscriptionSubscribeRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    final current = _subscriptionOf(state);
    emit(SubscriptionSubscribing(plan: event.plan, subscription: current));
    final result = await _subscribeUseCase(SubscribeParams(plan: event.plan));
    result.fold(
      (f) => emit(SubscriptionActionFailure(message: f.message, subscription: current)),
      (r) => emit(SubscriptionApprovalUrlReady(approveUrl: r.approveUrl, subscription: current)),
    );
  }

  Future<void> _onApprovalPollRequested(
    SubscriptionApprovalPollRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    final current = _subscriptionOf(state);
    emit(SubscriptionPolling(subscription: current));

    var last = current;
    for (var attempt = 0; attempt < _pollAttempts; attempt++) {
      await Future.delayed(_pollDelay);
      final result = await _getSubscriptionStatusUseCase(const NoParams());
      var stop = false;
      result.fold(
        (f) {
          emit(SubscriptionActionFailure(message: f.message, subscription: current));
          stop = true;
        },
        (sub) {
          last = sub;
          if (sub != null && sub.isActive) {
            emit(SubscriptionLoaded(subscription: sub));
            stop = true;
          }
        },
      );
      if (stop) return;
    }

    emit(SubscriptionPollingTimedOut(subscription: last));
  }

  Future<void> _onCancelRequested(
    SubscriptionCancelRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    final current = _subscriptionOf(state);
    emit(SubscriptionCancelling(subscription: current));
    final cancelResult = await _cancelSubscriptionUseCase(const NoParams());

    var failed = false;
    cancelResult.fold(
      (f) {
        emit(SubscriptionActionFailure(message: f.message, subscription: current));
        failed = true;
      },
      (_) {},
    );
    if (failed) return;

    final refreshed = await _getSubscriptionStatusUseCase(const NoParams());
    refreshed.fold(
      (f) => emit(SubscriptionActionFailure(message: f.message)),
      (sub) => emit(SubscriptionLoaded(subscription: sub)),
    );
  }
}
