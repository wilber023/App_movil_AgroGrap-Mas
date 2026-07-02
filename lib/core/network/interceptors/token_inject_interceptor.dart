import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';

/// Inyecta `Authorization: Bearer <token>` en cada request.
/// No tiene lógica de refresh ni de clearTokens — solo lectura.
class TokenInjectInterceptor extends Interceptor {
  const TokenInjectInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
