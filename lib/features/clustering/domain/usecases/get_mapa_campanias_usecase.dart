import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/estado_resumen_entity.dart';
import '../repositories/clustering_repository.dart';

class GetMapaCampaniasUseCase implements UseCase<MapaCampaniasEntity, NoParams> {
  final ClusteringRepository repository;

  const GetMapaCampaniasUseCase(this.repository);

  @override
  Future<Either<Failure, MapaCampaniasEntity>> call(NoParams params) {
    return repository.getMapaCampanias();
  }
}
