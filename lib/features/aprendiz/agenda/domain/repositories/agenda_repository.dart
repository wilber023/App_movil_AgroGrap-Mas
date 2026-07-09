import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../entities/agenda_activity_entity.dart';
import '../entities/agenda_overview_entity.dart';

/// Contrato del modulo Agenda (independiente de Mi Cultivo).
abstract class AgendaRepository {
  Future<Either<Failure, AgendaOverviewEntity>> getAgendaOverview();

  Future<Either<Failure, AgendaActivityEntity>> completeActivity(
    String activityId,
  );

  Future<Either<Failure, AgendaActivityEntity>> postponeActivity(
    String activityId,
    String reason,
  );
}
