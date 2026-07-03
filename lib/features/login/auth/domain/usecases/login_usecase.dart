// =============================================================================
// Feature: Auth -- Caso de Uso: Login
// =============================================================================
// Capa: Domain
// Regla: Un caso de uso encapsula UNA SOLA regla de negocio.
//        Implementa el contrato UseCase<Type, Params> de core.
// =============================================================================

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Ejecuta el inicio de sesion con credenciales del usuario.
///
/// Recibe [LoginParams] con username y password.
/// Retorna [UserEntity] con tokens de sesion o un [Failure].
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) {
    return repository.login(
      username: params.username,
      password: params.password,
    );
  }
}

/// Parametros requeridos para el caso de uso de login.
class LoginParams extends Equatable {
  final String username;
  final String password;

  const LoginParams({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}
