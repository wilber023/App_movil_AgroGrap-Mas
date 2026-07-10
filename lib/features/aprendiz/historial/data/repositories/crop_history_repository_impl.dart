import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/network_info.dart';
import '../../domain/entities/crop_event_entity.dart';
import '../../domain/repositories/crop_history_repository.dart';
import '../datasources/crop_history_remote_datasource.dart';
import '../datasources/crop_history_local_datasource.dart';

class CropHistoryRepositoryImpl implements CropHistoryRepository {
  final CropHistoryRemoteDataSource remoteDataSource;
  final CropHistoryLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CropHistoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CropEventEntity>>> getCropHistory() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteHistory = await remoteDataSource.getCropHistory();
        await localDataSource.cacheCropHistory(remoteHistory);
        return Right(remoteHistory);
      } catch (e) {
        final localHistory = await localDataSource.getCachedCropHistory();
        if (localHistory != null) {
          return Right(localHistory);
        }
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      final localHistory = await localDataSource.getCachedCropHistory();
      if (localHistory != null) {
        return Right(localHistory);
      }
      return const Left(NetworkFailure());
    }
  }
}
