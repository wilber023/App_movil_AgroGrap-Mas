import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/agenda_overview_entity.dart';
import '../repositories/agenda_repository.dart';

class GetAgendaOverviewUseCase implements UseCase<AgendaOverviewEntity, NoParams> {
  final AgendaRepository repository;

  GetAgendaOverviewUseCase(this.repository);

  @override
  Future<Either<Failure, AgendaOverviewEntity>> call(NoParams params) {
    return repository.getAgendaOverview();
  }
}
