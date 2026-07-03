import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/diagnosis_entity.dart';

abstract class DiagnosisRepository {
  Future<Either<Failure, DiagnosisEntity>> analyzeCrop({required String imagePath});
  Future<Either<Failure, List<DiagnosisEntity>>> getHistory();
}
