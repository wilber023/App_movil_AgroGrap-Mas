import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/agenda_overview_entity.dart';
import '../repositories/agenda_repository.dart';

class GenerateAgendaParams extends Equatable {
  final String cultivo;
  final String? enfermedad;
  final String tratamiento;
  final String? prevencion;
  final String? currentStage;

  const GenerateAgendaParams({
    required this.cultivo,
    this.enfermedad,
    required this.tratamiento,
    this.prevencion,
    this.currentStage,
  });

  @override
  List<Object?> get props => [cultivo, enfermedad, tratamiento, prevencion, currentStage];
}

class GenerateAgendaUseCase implements UseCase<AgendaOverviewEntity, GenerateAgendaParams> {
  final AgendaRepository repository;

  const GenerateAgendaUseCase(this.repository);

  @override
  Future<Either<Failure, AgendaOverviewEntity>> call(GenerateAgendaParams params) {
    return repository.generarAgenda(
      cultivo: params.cultivo,
      enfermedad: params.enfermedad,
      tratamiento: params.tratamiento,
      prevencion: params.prevencion,
      currentStage: params.currentStage,
    );
  }
}
