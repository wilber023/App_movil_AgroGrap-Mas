import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';

abstract class AprendizDiagnosisRepository {
  Future<Either<Failure, DiagnosisEntity>> analyzeCrop({required String imagePath, String? description});
}
