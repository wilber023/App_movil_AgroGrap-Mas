import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/treatment_entity.dart';

abstract interface class TreatmentRepository {
  Future<Either<Failure, List<TreatmentEntity>>> getAgenda();
  Future<Either<Failure, TreatmentEntity>> getById(String id);
  Future<Either<Failure, void>> markStepComplete({
    required String treatmentId,
    required String stepId,
  });
}
