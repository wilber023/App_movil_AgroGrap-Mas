import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/alerta_epidemiologica_entity.dart';
import '../entities/estado_resumen_entity.dart';

abstract interface class ClusteringRepository {
  Future<Either<Failure, MapaCampaniasEntity>> getMapaCampanias();

  Future<Either<Failure, AlertaEpidemiologicaEntity>> getAlerta({String? estado});

  /// Reporta un diagnóstico exitoso al sistema de Clustering
  /// (fire-and-forget). Nunca lanza ni devuelve un `Failure`: cualquier
  /// error de red/servidor se descarta en la implementación, ya que el
  /// resultado de un diagnóstico jamás debe depender de este envío.
  Future<void> enviarReporte({
    required String cultivo,
    required String plaga,
    required String estado,
  });
}
