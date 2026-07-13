import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/treatment_entity.dart';

abstract interface class TreatmentRepository {
  /// Genera (reemplazando el plan activo anterior, si lo había) la agenda
  /// de tratamiento a partir de un diagnóstico. Requiere conexión -- ver
  /// `AgendaRepository.generarAgenda`.
  Future<Either<Failure, void>> generateFromDiagnosis({
    required String diagnosisId,
    required String diseaseName,
    required String cropName,
    required String llmDiagnostico,
    required String llmTratamiento,
    required String llmPrevencion,
  });

  /// `true` si [diagnosisId] es el diagnóstico que generó el plan
  /// actualmente activo (lectura local, sin red -- para la UI del botón
  /// "Agregar a la agenda").
  bool isActivePlanFor(String diagnosisId);

  Future<Either<Failure, List<TreatmentEntity>>> getAgenda();
  Future<Either<Failure, TreatmentEntity>> getById(String id);
  Future<Either<Failure, void>> markStepComplete({
    required String treatmentId,
    required String stepId,
  });
  Future<Either<Failure, void>> rescheduleStep({
    required String treatmentId,
    required String stepId,
    required DateTime newDate,
  });
  Future<Either<Failure, void>> setRemindersActive({
    required String treatmentId,
    required bool active,
  });
}
