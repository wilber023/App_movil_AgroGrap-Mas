import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../entities/agenda_activity_entity.dart';
import '../entities/agenda_overview_entity.dart';

/// Contrato del modulo Agenda (independiente de Mi Cultivo). Una instancia
/// sirve a un solo rol (Agricultor o Aprendiz) -- ver `AgendaRepositoryImpl`.
abstract class AgendaRepository {
  /// Genera (reemplazando cualquier plan anterior de este usuario+rol) la
  /// agenda a partir de un diagnostico. Requiere conexion: el calendario lo
  /// calcula el backend (LLM o regla determinista), no se puede fabricar
  /// localmente sin inventar un dato que no existe todavia.
  Future<Either<Failure, AgendaOverviewEntity>> generarAgenda({
    required String cultivo,
    String? enfermedad,
    required String tratamiento,
    String? prevencion,
    String? currentStage,
  });

  Future<Either<Failure, AgendaOverviewEntity>> getAgendaOverview();

  Future<Either<Failure, AgendaActivityEntity>> completeActivity(
    String activityId,
  );

  Future<Either<Failure, AgendaActivityEntity>> postponeActivity(
    String activityId,
    String reason,
  );
}
