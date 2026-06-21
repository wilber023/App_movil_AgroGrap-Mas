// =============================================================================
// Feature: Auth -- Entidad de Usuario
// =============================================================================
// Capa: Domain
// Regla: Las entidades son objetos inmutables que representan los conceptos
//        del negocio. No dependen de ningun framework ni paquete externo
//        salvo Equatable para comparacion por valor.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Entidad principal de usuario en el dominio de autenticacion.
///
/// Representa al agricultor registrado en AgroGraph-MAS.
/// Los campos reflejan la informacion capturada en la pantalla
/// "Crea tu cuenta" del proyecto Stitch.
class UserEntity extends Equatable {
  /// Identificador unico del usuario (UUID del backend).
  final String id;

  /// Nombre completo del usuario.
  final String fullName;

  /// Alias o nombre de usuario para mostrar en la UI.
  final String username;

  /// Correo electronico (opcional segun el flujo de Stitch).
  final String? email;

  /// Numero de telefono (metodo de contacto principal en zonas rurales).
  final String? phone;

  /// URL del avatar del usuario (puede ser null si no se ha subido).
  final String? avatarUrl;

  /// Token de acceso JWT (almacenado tras login exitoso).
  final String? accessToken;

  /// Token de refresco (para renovar la sesion sin re-autenticar).
  final String? refreshToken;

  /// Indica si el usuario fue creado en modo offline (sin verificar con el servidor).
  final bool isLocalOnly;

  /// Fecha de creacion de la cuenta.
  final DateTime? createdAt;

  /// Rol del usuario en el sistema: "agricultor", "aprendiz_agricola" o "admin".
  final String? role;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.username,
    this.email,
    this.phone,
    this.avatarUrl,
    this.accessToken,
    this.refreshToken,
    this.isLocalOnly = false,
    this.createdAt,
    this.role,
  });

  /// Usuario vacio para estados iniciales.
  static const UserEntity empty = UserEntity(
    id: '',
    fullName: '',
    username: '',
  );

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;

  bool get isEmpty => id.isEmpty;

  bool get isAgricultor => role == 'agricultor';
  bool get isAprendiz => role == 'aprendiz_agricola';
  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [
        id,
        fullName,
        username,
        email,
        phone,
        avatarUrl,
        accessToken,
        refreshToken,
        isLocalOnly,
        createdAt,
        role,
      ];
}
