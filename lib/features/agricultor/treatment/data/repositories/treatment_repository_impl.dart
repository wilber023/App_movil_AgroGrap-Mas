import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../domain/entities/treatment_entity.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../datasources/treatment_local_datasource.dart';

class TreatmentRepositoryImpl implements TreatmentRepository {
  final TreatmentLocalDataSource localDataSource;

  const TreatmentRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<TreatmentEntity>>> getAgenda() async {
    try {
      final result = await localDataSource.getAgenda();
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TreatmentEntity>> getById(String id) async {
    try {
      final all = await localDataSource.getAgenda();
      final found = all.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Tratamiento no encontrado'),
      );
      return Right(found);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markStepComplete({
    required String treatmentId,
    required String stepId,
  }) async {
    try {
      await localDataSource.markStepComplete(
        treatmentId: treatmentId,
        stepId: stepId,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rescheduleStep({
    required String treatmentId,
    required String stepId,
    required DateTime newDate,
  }) async {
    try {
      await localDataSource.rescheduleStep(
        treatmentId: treatmentId,
        stepId: stepId,
        newDate: newDate,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setRemindersActive({
    required String treatmentId,
    required bool active,
  }) async {
    try {
      await localDataSource.setRemindersActive(
        treatmentId: treatmentId,
        active: active,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
