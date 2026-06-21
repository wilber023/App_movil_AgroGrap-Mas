// =============================================================================
// Feature: Auth -- Caso de Uso: Register
// =============================================================================
// Capa: Domain
// =============================================================================

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/profile_type.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return repository.register(
      fullName: params.fullName,
      username: params.username,
      password: params.password,
      profileType: params.profileType,
      email: params.email,
      phone: params.phone,
    );
  }
}

class RegisterParams extends Equatable {
  final String fullName;
  final String username;
  final String password;
  final ProfileType profileType;
  final String? email;
  final String? phone;

  const RegisterParams({
    required this.fullName,
    required this.username,
    required this.password,
    required this.profileType,
    this.email,
    this.phone,
  });

  @override
  List<Object?> get props => [
        fullName,
        username,
        password,
        profileType,
        email,
        phone,
      ];
}
