// =============================================================================
// AgroGraph-MAS -- Contrato Base de Casos de Uso
// =============================================================================

import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Contrato base para todos los casos de uso de la aplicacion.
///
/// [Type] es el tipo de retorno exitoso.
/// [Params] son los parametros de entrada.
///
/// Ejemplo de implementacion:
/// ```dart
/// class GetDashboard implements UseCase<DashboardEntity, NoParams> {
///   final HomeRepository repository;
///   GetDashboard(this.repository);
///
///   @override
///   Future<Either<Failure, DashboardEntity>> call(NoParams params) {
///     return repository.getDashboard();
///   }
/// }
/// ```
abstract interface class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Parametro vacio para casos de uso sin argumentos.
class NoParams {
  const NoParams();
}
