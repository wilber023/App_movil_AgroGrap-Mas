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

class GenerateTreatmentFromDiagnosisUseCase
    implements UseCase<void, GenerateTreatmentFromDiagnosisParams> {
  final TreatmentRepository repository;
  const GenerateTreatmentFromDiagnosisUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(GenerateTreatmentFromDiagnosisParams params) {
    return repository.generateFromDiagnosis(
      diagnosisId: params.diagnosisId,
      diseaseName: params.diseaseName,
      cropName: params.cropName,
      llmDiagnostico: params.llmDiagnostico,
      llmTratamiento: params.llmTratamiento,
      llmPrevencion: params.llmPrevencion,
    );
  }
}

class GenerateTreatmentFromDiagnosisParams extends Equatable {
  final String diagnosisId;
  final String diseaseName;
  final String cropName;
  final String llmDiagnostico;
  final String llmTratamiento;
  final String llmPrevencion;

  const GenerateTreatmentFromDiagnosisParams({
    required this.diagnosisId,
    required this.diseaseName,
    required this.cropName,
    required this.llmDiagnostico,
    required this.llmTratamiento,
    required this.llmPrevencion,
  });

  @override
  List<Object?> get props =>
      [diagnosisId, diseaseName, cropName, llmDiagnostico, llmTratamiento, llmPrevencion];
}

class IsActivePlanForUseCase {
  final TreatmentRepository repository;
  const IsActivePlanForUseCase(this.repository);

  bool call(String diagnosisId) => repository.isActivePlanFor(diagnosisId);
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

class RescheduleStepUseCase
    implements UseCase<void, RescheduleStepParams> {
  final TreatmentRepository repository;
  const RescheduleStepUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RescheduleStepParams params) {
    return repository.rescheduleStep(
      treatmentId: params.treatmentId,
      stepId: params.stepId,
      newDate: params.newDate,
    );
  }
}

class RescheduleStepParams extends Equatable {
  final String treatmentId;
  final String stepId;
  final DateTime newDate;
  const RescheduleStepParams({
    required this.treatmentId,
    required this.stepId,
    required this.newDate,
  });

  @override
  List<Object?> get props => [treatmentId, stepId, newDate];
}

class SetRemindersActiveUseCase
    implements UseCase<void, SetRemindersActiveParams> {
  final TreatmentRepository repository;
  const SetRemindersActiveUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SetRemindersActiveParams params) {
    return repository.setRemindersActive(
      treatmentId: params.treatmentId,
      active: params.active,
    );
  }
}

class SetRemindersActiveParams extends Equatable {
  final String treatmentId;
  final bool active;
  const SetRemindersActiveParams({
    required this.treatmentId,
    required this.active,
  });

  @override
  List<Object?> get props => [treatmentId, active];
}
