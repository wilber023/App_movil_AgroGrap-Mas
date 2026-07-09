import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/agenda_activity_entity.dart';
import '../repositories/agenda_repository.dart';

class CompleteAgendaActivityUseCase
    implements UseCase<AgendaActivityEntity, CompleteAgendaActivityParams> {
  final AgendaRepository repository;

  CompleteAgendaActivityUseCase(this.repository);

  @override
  Future<Either<Failure, AgendaActivityEntity>> call(
    CompleteAgendaActivityParams params,
  ) {
    return repository.completeActivity(params.activityId);
  }
}

class CompleteAgendaActivityParams extends Equatable {
  final String activityId;
  const CompleteAgendaActivityParams({required this.activityId});

  @override
  List<Object?> get props => [activityId];
}
