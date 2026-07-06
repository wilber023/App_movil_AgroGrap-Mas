// =============================================================================
// Feature: Auth -- Modelo de Usuario (Serialización JSON)
// =============================================================================
// Capa: Data
// Mapea el contrato exacto del backend (snake_case) a [UserEntity].
// Forma del JSON (login / register / refresh / GET /users/me):
// {
//   "id", "full_name", "username", "email", "phone", "avatar_url",
//   "access_token", "refresh_token", "is_local_only", "created_at", "role"
// }
// =============================================================================

import '../../domain/entities/user_entity.dart';

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
    super.role,
  });

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
      role: json['role'] as String?,
    );
  }

  /// JSON para enviar al backend (solo campos de perfil, sin tokens).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'is_local_only': isLocalOnly,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (role != null) 'role': role,
    };
  }

  /// JSON para persistir en Hive: solo perfil, SIN tokens.
  ///
  /// MASVS-STORAGE (prevención de fuga de datos sensibles): los tokens ya
  /// se guardan por separado en `flutter_secure_storage` (Keystore/Keychain)
  /// vía [TokenStorage]. Duplicarlos aquí en texto plano anularía ese
  /// control, ya que Hive no cifra su contenido en disco.
  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'is_local_only': isLocalOnly,
      'created_at': createdAt?.toIso8601String(),
      'role': role,
    };
  }

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
      role: entity.role,
    );
  }
}
