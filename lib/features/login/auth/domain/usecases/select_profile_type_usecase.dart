// =============================================================================
// Feature: Auth -- Caso de Uso: Seleccionar Tipo de Perfil
// =============================================================================
// Capa: Domain
// Responsabilidad: Guardar el tipo de perfil seleccionado por el usuario.
// =============================================================================

import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/profile_type.dart';
import '../repositories/auth_repository.dart';

class SelectProfileTypeUseCase implements UseCase<void, ProfileType> {
  final AuthRepository repository;

  const SelectProfileTypeUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ProfileType params) {
    return repository.saveSelectedProfileType(params);
  }
}
