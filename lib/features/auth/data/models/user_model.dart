// =============================================================================
// Feature: Auth -- Modelo de Usuario (Serializacion JSON)
// =============================================================================
// Capa: Data
// Regla: Los modelos extienden las entidades del dominio y agregan
//        logica de serializacion (fromJson/toJson). Esto mantiene la
//        capa de dominio libre de dependencias de infraestructura.
// =============================================================================

import '../../domain/entities/user_entity.dart';

/// Modelo de datos para [UserEntity] con soporte de serializacion JSON.
///
/// Se usa en la comunicacion con el backend (API REST) y en la
/// persistencia local (Hive como cache offline).
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.username,
    super.email,
    super.phone,
    super.avatarUrl,
    super.accessToken,
    super.refreshToken,
    super.isLocalOnly,
    super.createdAt,
  });

  /// Crea una instancia desde un mapa JSON (respuesta del backend).
  ///
  /// Estructura esperada del JSON:
  /// ```json
  /// {
  ///   "id": "uuid-v4",
  ///   "full_name": "Wilber Hernandez",
  ///   "username": "wil_hdz",
  ///   "email": "wil@example.com",
  ///   "phone": "+52 123 456 7890",
  ///   "avatar_url": "https://...",
  ///   "access_token": "eyJhbGci...",
  ///   "refresh_token": "dGhpcyBp...",
  ///   "is_local_only": false,
  ///   "created_at": "2026-06-05T03:51:09.010663Z"
  /// }
  /// ```
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      isLocalOnly: json['is_local_only'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Convierte la instancia a un mapa JSON para enviar al backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (accessToken != null) 'access_token': accessToken,
      if (refreshToken != null) 'refresh_token': refreshToken,
      'is_local_only': isLocalOnly,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Convierte la instancia a un mapa JSON para almacenar en Hive (cache local).
  /// Incluye TODOS los campos, incluyendo tokens, para persistencia offline.
  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'is_local_only': isLocalOnly,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Crea un [UserModel] desde la entidad de dominio.
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      fullName: entity.fullName,
      username: entity.username,
      email: entity.email,
      phone: entity.phone,
      avatarUrl: entity.avatarUrl,
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      isLocalOnly: entity.isLocalOnly,
      createdAt: entity.createdAt,
    );
  }
}
