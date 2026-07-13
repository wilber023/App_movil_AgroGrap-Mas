import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/alerta_epidemiologica_entity.dart';
import '../repositories/clustering_repository.dart';

class GetAlertaParams extends Equatable {
  /// Entidad federativa a consultar. `null` o vacío -> alerta nacional.
  final String? estado;

  const GetAlertaParams({this.estado});

  @override
  List<Object?> get props => [estado];
}

class GetAlertaUseCase implements UseCase<AlertaEpidemiologicaEntity, GetAlertaParams> {
  final ClusteringRepository repository;

  const GetAlertaUseCase(this.repository);

  @override
  Future<Either<Failure, AlertaEpidemiologicaEntity>> call(GetAlertaParams params) {
    return repository.getAlerta(estado: params.estado);
  }
}
