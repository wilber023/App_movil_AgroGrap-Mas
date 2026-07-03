import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/treatment_entity.dart';
import '../repositories/treatment_repository.dart';

class GetTreatmentAgendaUseCase
    implements UseCase<List<TreatmentEntity>, NoParams> {
  final TreatmentRepository repository;
  const GetTreatmentAgendaUseCase(this.repository);

  @override
  Future<Either<Failure, List<TreatmentEntity>>> call(NoParams params) {
    return repository.getAgenda();
  }
}

class MarkStepCompleteUseCase
    implements UseCase<void, MarkStepCompleteParams> {
  final TreatmentRepository repository;
  const MarkStepCompleteUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkStepCompleteParams params) {
    return repository.markStepComplete(
      treatmentId: params.treatmentId,
      stepId: params.stepId,
    );
  }
}

class MarkStepCompleteParams extends Equatable {
  final String treatmentId;
  final String stepId;
  const MarkStepCompleteParams({
    required this.treatmentId,
    required this.stepId,
  });

  @override
  List<Object?> get props => [treatmentId, stepId];
}
