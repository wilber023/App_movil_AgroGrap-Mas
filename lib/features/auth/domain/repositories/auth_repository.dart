// =============================================================================
// Feature: Auth -- Contrato del Repositorio
// =============================================================================
// Capa: Domain
// Regla: Este contrato define QUE debe hacer el repositorio, no COMO.
//        La implementacion concreta vive en la capa de datos.
//        Retorna Either<Failure, T> para manejo funcional de errores.
// =============================================================================

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/profile_type.dart';
import '../entities/user_entity.dart';

/// Contrato abstracto del repositorio de autenticacion.
///
/// Define las operaciones disponibles para login, registro,
/// verificacion de sesion y cierre de sesion.
abstract interface class AuthRepository {
  /// Inicia sesion con nombre de usuario y contrasena.
  ///
  /// Retorna [UserEntity] con tokens si la autenticacion es exitosa,
  /// o un [Failure] en caso de error (credenciales invalidas, sin red, etc.).
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  });

  /// Registra un nuevo usuario en la plataforma.
  ///
  /// Los campos [email] y [phone] son opcionales, respetando el diseno
  /// "Sin correo obligatorio" del flujo de Stitch.
  Future<Either<Failure, UserEntity>> register({
    required String fullName,
    required String username,
    required String password,
    String? email,
    String? phone,
  });

  /// Verifica si existe una sesion activa almacenada localmente.
  ///
  /// Retorna el [UserEntity] cacheado si hay un token valido,
  /// o un [Failure] si no hay sesion o el token expiro.
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Cierra la sesion activa (invalida tokens en servidor y limpia cache local).
  Future<Either<Failure, void>> logout();

  /// Refresca el token de acceso usando el refresh token almacenado.
  Future<Either<Failure, UserEntity>> refreshSession();

  /// Guarda el tipo de perfil seleccionado por el usuario.
  Future<Either<Failure, void>> saveSelectedProfileType(ProfileType profileType);

  /// Recupera el tipo de perfil seleccionado por el usuario.
  Future<Either<Failure, ProfileType?>> getSelectedProfileType();
}

