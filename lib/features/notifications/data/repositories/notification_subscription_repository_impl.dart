import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_subscription_entity.dart';
import '../../domain/repositories/notification_subscription_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationSubscriptionRepositoryImpl implements NotificationSubscriptionRepository {
  final NotificationRemoteDataSource remoteDataSource;

  const NotificationSubscriptionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, NotificationSubscriptionEntity>> subscribe({
    required String fcmToken,
    required String estado,
    List<String>? cultivos,
  }) async {
    try {
      final result = await remoteDataSource.subscribe(
        fcmToken: fcmToken,
        estado: estado,
        cultivos: cultivos,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(ServerFailure(message: 'No se pudo activar las alertas.', statusCode: null));
    }
  }

  @override
  Future<Either<Failure, NotificationSubscriptionEntity?>> getMySubscription() async {
    try {
      final result = await remoteDataSource.getMySubscription();
      return Right(result);
    } on ServerException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(ServerFailure(message: 'No se pudo consultar tus alertas.', statusCode: null));
    }
  }

  @override
  Future<Either<Failure, void>> cancelSubscription() async {
    try {
      await remoteDataSource.cancelSubscription();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(ServerFailure(message: 'No se pudieron desactivar las alertas.', statusCode: null));
    }
  }

  Failure _map(ServerException e) {
    if (e.statusCode == 401) {
      return AuthFailure(message: e.message, statusCode: e.statusCode);
    }
    return ServerFailure(message: e.message, statusCode: e.statusCode);
  }
}
