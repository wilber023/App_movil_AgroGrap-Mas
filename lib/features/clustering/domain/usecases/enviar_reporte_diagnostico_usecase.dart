import 'package:equatable/equatable.dart';

import '../repositories/clustering_repository.dart';

class EnviarReporteDiagnosticoParams extends Equatable {
  final String cultivo;
  final String plaga;
  final String estado;

  const EnviarReporteDiagnosticoParams({
    required this.cultivo,
    required this.plaga,
    required this.estado,
  });

  @override
  List<Object?> get props => [cultivo, plaga, estado];
}

/// Reporta un diagnóstico exitoso al sistema de Clustering
/// (fire-and-forget). No implementa `UseCase<T, Params>` porque no hay un
/// resultado ni un `Failure` que propagar: [ClusteringRepository.enviarReporte]
/// ya descarta cualquier error internamente.
class EnviarReporteDiagnosticoUseCase {
  final ClusteringRepository repository;

  const EnviarReporteDiagnosticoUseCase(this.repository);

  Future<void> call(EnviarReporteDiagnosticoParams params) {
    return repository.enviarReporte(
      cultivo: params.cultivo,
      plaga: params.plaga,
      estado: params.estado,
    );
  }
}
