// =============================================================================
// Core -- Token Storage
// =============================================================================
// Capa: Core / Storage
// Responsabilidad única: leer y escribir tokens (access + refresh).
// Es el único punto de verdad que usan los interceptores de red para
// adjuntar o renovar el Authorization header sin acoplarse a la feature Auth.
//
// MASVS-STORAGE: los tokens se persisten en `flutter_secure_storage`
// (Keystore en Android / Keychain en iOS), nunca en Hive/SharedPreferences
// en texto plano — un token robado de un backup o de un dispositivo con
// acceso al filesystem no debe ser legible.
// =============================================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clearTokens();
}

class TokenStorageImpl implements TokenStorage {
  final FlutterSecureStorage _storage;

  static const _accessKey = 'ACCESS_TOKEN';
  static const _refreshKey = 'REFRESH_TOKEN';

  const TokenStorageImpl(this._storage);

  @override
  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
