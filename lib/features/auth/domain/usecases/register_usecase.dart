// =============================================================================
// Feature: Auth -- Caso de Uso: Register
// =============================================================================
// Capa: Domain
// =============================================================================

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Ejecuta el registro de un nuevo usuario en AgroGraph-MAS.
///
/// El flujo de Stitch indica: "Sin correo obligatorio, tus datos se
/// guardan localmente", por lo que [email] y [phone] son opcionales.
class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return repository.register(
      fullName: params.fullName,
      username: params.username,
      password: params.password,
      email: params.email,
      phone: params.phone,
    );
  }
}

/// Parametros requeridos para el caso de uso de registro.
class RegisterParams extends Equatable {
  final String fullName;
  final String username;
  final String password;
  final String? email;
  final String? phone;

  const RegisterParams({
    required this.fullName,
    required this.username,
    required this.password,
    this.email,
    this.phone,
  });

  @override
  List<Object?> get props => [fullName, username, password, email, phone];
}
