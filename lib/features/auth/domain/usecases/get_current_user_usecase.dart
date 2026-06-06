// =============================================================================
// Feature: Auth -- Caso de Uso: Get Current User
// =============================================================================
// Capa: Domain
// =============================================================================

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Recupera el usuario actualmente autenticado desde el cache local.
///
/// Se usa al iniciar la app para verificar si hay sesion activa y
/// decidir si mostrar la pantalla de Bienvenida o el Dashboard.
class GetCurrentUserUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  const GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.getCurrentUser();
  }
}
