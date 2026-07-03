// =============================================================================
// Feature: Auth -- Caso de Uso: Logout
// =============================================================================
// Capa: Domain
// =============================================================================

import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Cierra la sesion del usuario actual.
///
/// Invalida tokens en el servidor y limpia el cache local.
class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  const LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.logout();
  }
}
