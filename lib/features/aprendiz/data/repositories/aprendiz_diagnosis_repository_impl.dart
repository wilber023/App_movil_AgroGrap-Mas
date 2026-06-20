import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';
import '../../domain/repositories/aprendiz_diagnosis_repository.dart';
import '../datasources/aprendiz_diagnosis_remote_datasource.dart';
import '../datasources/aprendiz_diagnosis_local_datasource.dart';

class AprendizDiagnosisRepositoryImpl implements AprendizDiagnosisRepository {
  final AprendizDiagnosisRemoteDataSource remoteDataSource;
  final AprendizDiagnosisLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AprendizDiagnosisRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DiagnosisEntity>> analyzeCrop({required String imagePath, String? description}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.analyzeCrop(imagePath: imagePath, description: description);
        return Right(result);
      } catch (e) {
        // En caso de fallo de red en la API, intentar fallback offline simulado
        try {
          final localResult = await localDataSource.analyzeCropOffline(imagePath: imagePath, description: description);
          return Right(localResult);
        } catch (localError) {
          return Left(ServerFailure(message: 'Error remoto: \$e. Error local: \$localError'));
        }
      }
    } else {
      // Modo offline simulado por JSON
      try {
        final localResult = await localDataSource.analyzeCropOffline(imagePath: imagePath, description: description);
        return Right(localResult);
      } catch (e) {
        return Left(ServerFailure(message: 'Error en el modelo local: \$e'));
      }
    }
  }
}
