// =============================================================================
// Core -- Token Storage
// =============================================================================
// Capa: Core / Storage
// Responsabilidad única: leer y escribir tokens (access + refresh) en Hive.
// Es el único punto de verdad que usan los interceptores de red para
// adjuntar o renovar el Authorization header sin acoplarse a la feature Auth.
// =============================================================================

import 'package:hive/hive.dart';

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
  final Box<String> _box;

  static const _accessKey = 'ACCESS_TOKEN';
  static const _refreshKey = 'REFRESH_TOKEN';

  const TokenStorageImpl(this._box);

  @override
  Future<String?> getAccessToken() async => _box.get(_accessKey);

  @override
  Future<String?> getRefreshToken() async => _box.get(_refreshKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put(_accessKey, accessToken);
    await _box.put(_refreshKey, refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await _box.delete(_accessKey);
    await _box.delete(_refreshKey);
  }
}
