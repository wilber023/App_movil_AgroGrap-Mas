import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/subscribe_result_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_datasource.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;

  const SubscriptionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, SubscribeResultEntity>> subscribe({required String plan}) async {
    try {
      final result = await remoteDataSource.subscribe(plan: plan);
      return Right(result);
    } on ServerException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(
        ServerFailure(message: 'No se pudo iniciar la suscripción.', statusCode: null),
      );
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>> getSubscription() async {
    if (kDebugMode) {
      debugPrint('[SUB-TRACE] 5) SubscriptionRepositoryImpl.getSubscription -- '
          'llamando al RemoteDataSource');
    }
    try {
      final subscription = await remoteDataSource.getSubscription();
      return Right(subscription);
    } on ServerException catch (e) {
      if (kDebugMode) {
        debugPrint('[SUB-TRACE] 10) SubscriptionRepositoryImpl -- capturo ServerException '
            'statusCode=${e.statusCode} message="${e.message}" -> mapeando a Failure');
      }
      return Left(_map(e));
    } catch (_) {
      return const Left(
        ServerFailure(message: 'No se pudo consultar tu suscripción.', statusCode: null),
      );
    }
  }

  @override
  Future<Either<Failure, void>> cancelSubscription() async {
    try {
      await remoteDataSource.cancel();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(
        ServerFailure(message: 'No se pudo cancelar tu suscripción.', statusCode: null),
      );
    }
  }

  Failure _map(ServerException e) {
    if (e.statusCode == 401) {
      return AuthFailure(message: e.message, statusCode: e.statusCode);
    }
    return ServerFailure(message: e.message, statusCode: e.statusCode);
  }
}
