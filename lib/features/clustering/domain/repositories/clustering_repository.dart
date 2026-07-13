import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/alerta_epidemiologica_entity.dart';
import '../entities/estado_resumen_entity.dart';

abstract interface class ClusteringRepository {
  Future<Either<Failure, MapaCampaniasEntity>> getMapaCampanias();

  Future<Either<Failure, AlertaEpidemiologicaEntity>> getAlerta({String? estado});
}
