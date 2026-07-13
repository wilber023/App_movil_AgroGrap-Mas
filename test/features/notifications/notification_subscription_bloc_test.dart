import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrograp_movil/core/error/failures.dart';
import 'package:agrograp_movil/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:agrograp_movil/features/notifications/domain/entities/notification_subscription_entity.dart';
import 'package:agrograp_movil/features/notifications/domain/entities/push_notification_entry_entity.dart';
import 'package:agrograp_movil/features/notifications/domain/repositories/notification_history_repository.dart';
import 'package:agrograp_movil/features/notifications/domain/repositories/notification_subscription_repository.dart';
import 'package:agrograp_movil/features/notifications/domain/usecases/cancel_alert_subscription_usecase.dart';
import 'package:agrograp_movil/features/notifications/domain/usecases/notification_preferences_usecases.dart';
import 'package:agrograp_movil/features/notifications/domain/usecases/subscribe_to_alerts_usecase.dart';
import 'package:agrograp_movil/features/notifications/presentation/bloc/notification_subscription_bloc.dart';

/// Fake en memoria de [NotificationSubscriptionRepository] -- controla si
/// `subscribe`/`cancelSubscription` fallan, tardan, o tienen éxito, sin red
/// real (mismo patrón que los demás tests del proyecto).
class _FakeSubscriptionRepository implements NotificationSubscriptionRepository {
  Duration remoteDelay = Duration.zero;
  Failure? failureToReturn;
  int subscribeCalls = 0;
  int cancelCalls = 0;

  @override
  Future<Either<Failure, NotificationSubscriptionEntity>> subscribe({
    required String fcmToken,
    required String estado,
    List<String>? cultivos,
  }) async {
    subscribeCalls++;
    if (remoteDelay > Duration.zero) await Future.delayed(remoteDelay);
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(NotificationSubscriptionEntity(
      userId: 'u1',
      fcmToken: fcmToken,
      estado: estado,
      cultivos: cultivos ?? const [],
    ));
  }

  @override
  Future<Either<Failure, NotificationSubscriptionEntity?>> getMySubscription() async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> cancelSubscription() async {
    cancelCalls++;
    if (remoteDelay > Duration.zero) await Future.delayed(remoteDelay);
    if (failureToReturn != null) return Left(failureToReturn!);
    return const Right(null);
  }
}

/// Fake en memoria de [NotificationHistoryRepository] -- solo la parte de
/// preferencias, que es la que usa este Bloc.
class _FakeHistoryRepository implements NotificationHistoryRepository {
  NotificationPreferencesEntity saved = NotificationPreferencesEntity.empty;
  final List<NotificationPreferencesEntity> saveCalls = [];

  @override
  Future<Either<Failure, NotificationPreferencesEntity>> getPreferences() async => Right(saved);

  @override
  Future<Either<Failure, void>> savePreferences(NotificationPreferencesEntity prefs) async {
    saved = prefs;
    saveCalls.add(prefs);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<PushNotificationEntryEntity>>> getHistory() async =>
      const Right([]);

  @override
  Future<Either<Failure, void>> saveReceived(PushNotificationEntryEntity entry) async =>
      const Right(null);
}

void main() {
  late _FakeSubscriptionRepository subRepo;
  late _FakeHistoryRepository historyRepo;
  late NotificationSubscriptionBloc bloc;

  setUp(() {
    subRepo = _FakeSubscriptionRepository();
    historyRepo = _FakeHistoryRepository();
    bloc = NotificationSubscriptionBloc(
      subscribeUseCase: SubscribeToAlertsUseCase(subRepo),
      cancelUseCase: CancelAlertSubscriptionUseCase(subRepo),
      getPreferencesUseCase: GetNotificationPreferencesUseCase(historyRepo),
      savePreferencesUseCase: SaveNotificationPreferencesUseCase(historyRepo),
      getFcmToken: () async => 'fake-fcm-token',
    );
  });

  tearDown(() => bloc.close());

  test(
    'Guardar con el POST a /suscripciones fallando (timeout simulado) -> '
    'el guardado local se completa y se confirma de inmediato, sin esperar '
    'al remoto ni emitir un estado de error',
    () async {
      subRepo.remoteDelay = const Duration(milliseconds: 200);
      subRepo.failureToReturn = const ServerFailure(message: 'timeout', statusCode: null);

      final states = <NotificationSubscriptionState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const NotificationSubscribeRequested(estado: 'Chiapas', cultivos: ['maíz']));

      final confirmed = await bloc.stream
          .firstWhere((s) => s is NotificationSubscriptionLoaded) as NotificationSubscriptionLoaded;

      // Confirmación inmediata: no se esperaron los 200ms del remoto.
      expect(confirmed.preferences.enabled, isTrue);
      expect(confirmed.preferences.estado, 'Chiapas');
      expect(confirmed.preferences.pushSyncPending, isTrue);

      // El guardado local ya ocurrió en Hive (fake) antes de esta confirmación.
      expect(historyRepo.saveCalls, isNotEmpty);
      expect(historyRepo.saved.enabled, isTrue);
      expect(historyRepo.saved.estado, 'Chiapas');

      // Se espera a que el remoto (que va a fallar) efectivamente termine,
      // para confirmar que su falla nunca produce un estado de error.
      await Future.delayed(const Duration(milliseconds: 300));
      expect(states.whereType<NotificationSubscriptionFailure>(), isEmpty);
      expect(subRepo.subscribeCalls, 1);

      await sub.cancel();
    },
  );

  test(
    'Guardar con el POST a /suscripciones exitoso -> además de la '
    'confirmación inmediata, actualiza pushSyncPending a false en segundo '
    'plano sin bloquear la primera confirmación',
    () async {
      subRepo.remoteDelay = const Duration(milliseconds: 50);
      subRepo.failureToReturn = null;

      final loadedStates = <NotificationSubscriptionLoaded>[];
      final sub = bloc.stream.listen((s) {
        if (s is NotificationSubscriptionLoaded) loadedStates.add(s);
      });

      bloc.add(const NotificationSubscribeRequested(estado: 'Sinaloa'));

      final first = await bloc.stream
          .firstWhere((s) => s is NotificationSubscriptionLoaded) as NotificationSubscriptionLoaded;
      expect(first.preferences.pushSyncPending, isTrue);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(loadedStates.last.preferences.pushSyncPending, isFalse);
      expect(historyRepo.saved.pushSyncPending, isFalse);

      await sub.cancel();
    },
  );

  test(
    'Desactivar con el DELETE a /suscripciones/yo fallando -> el guardado '
    'local (enabled: false) se completa y se confirma igual, sin bloquear '
    'ni fallar por el remoto',
    () async {
      historyRepo.saved = const NotificationPreferencesEntity(
        enabled: true,
        estado: 'Chiapas',
        cultivos: ['maíz'],
      );
      subRepo.remoteDelay = const Duration(milliseconds: 200);
      subRepo.failureToReturn = const ServerFailure(message: 'timeout', statusCode: null);

      final states = <NotificationSubscriptionState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const NotificationUnsubscribeRequested());

      final confirmed = await bloc.stream
          .firstWhere((s) => s is NotificationSubscriptionLoaded) as NotificationSubscriptionLoaded;

      expect(confirmed.preferences.enabled, isFalse);
      expect(historyRepo.saved.enabled, isFalse);

      await Future.delayed(const Duration(milliseconds: 300));
      expect(states.whereType<NotificationSubscriptionFailure>(), isEmpty);
      expect(subRepo.cancelCalls, 1);

      await sub.cancel();
    },
  );
}
