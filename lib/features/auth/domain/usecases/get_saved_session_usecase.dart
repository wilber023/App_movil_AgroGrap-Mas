// =============================================================================
// Feature: Auth -- Caso de Uso: Obtener Sesión Guardada
// =============================================================================
// Capa: Domain
// Responsabilidad: Obtener la sesión activa del usuario almacenada localmente.
// =============================================================================

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetSavedSessionUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  const GetSavedSessionUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.getCurrentUser();
  }
}
