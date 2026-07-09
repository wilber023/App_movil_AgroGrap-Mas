import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/agenda_activity_entity.dart';
import '../repositories/agenda_repository.dart';

class PostponeAgendaActivityUseCase
    implements UseCase<AgendaActivityEntity, PostponeAgendaActivityParams> {
  final AgendaRepository repository;

  PostponeAgendaActivityUseCase(this.repository);

  @override
  Future<Either<Failure, AgendaActivityEntity>> call(
    PostponeAgendaActivityParams params,
  ) {
    final reason = params.reason.trim();
    if (reason.isEmpty) {
      return Future.value(
        const Left(CacheFailure(message: 'Debes indicar un motivo para posponer la actividad.')),
      );
    }
    return repository.postponeActivity(params.activityId, reason);
  }
}

class PostponeAgendaActivityParams extends Equatable {
  final String activityId;
  final String reason;

  const PostponeAgendaActivityParams({
    required this.activityId,
    required this.reason,
  });

  @override
  List<Object?> get props => [activityId, reason];
}
