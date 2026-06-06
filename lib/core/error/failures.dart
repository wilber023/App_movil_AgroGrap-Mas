// =============================================================================
// AgroGraph-MAS -- Modelo de Errores (Clean Architecture)
// =============================================================================

import 'package:equatable/equatable.dart';

/// Clase base para todos los fallos de la aplicacion.
///
/// Cada feature retorna [Either<Failure, T>] en sus repositorios,
/// permitiendo un manejo de errores uniforme en la capa de presentacion.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Fallo originado por una peticion HTTP.
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

/// Fallo originado en la capa de almacenamiento local.
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Fallo por falta de conectividad (modo offline).
class NetworkFailure extends Failure {
  const NetworkFailure()
      : super(message: 'Sin conexion a internet. Los datos se sincronizaran automaticamente.');
}

/// Fallo de autenticacion (token expirado, credenciales invalidas).
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode});
}
