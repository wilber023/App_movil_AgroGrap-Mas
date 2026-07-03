import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/network_info.dart';
import '../../domain/entities/diagnosis_entity.dart';
import '../../domain/repositories/diagnosis_repository.dart';
import '../datasources/diagnosis_remote_datasource.dart';

class DiagnosisRepositoryImpl implements DiagnosisRepository {
  final DiagnosisRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DiagnosisRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DiagnosisEntity>> analyzeCrop({required String imagePath}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.analyzeCrop(imagePath);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<DiagnosisEntity>>> getHistory() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getHistory();
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
