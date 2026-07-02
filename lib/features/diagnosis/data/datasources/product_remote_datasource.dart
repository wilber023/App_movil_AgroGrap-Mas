import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/product_model.dart';

typedef ProductsResponse = ({
  String? productType,
  List<ProductModel> products,
});

abstract interface class ProductRemoteDataSource {
  Future<ProductsResponse> getRecommendedProducts({
    required String disease,
    String? crop,
  });
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  ProductRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  // JWT del servicio de productos (independiente del JWT del usuario).
  String? _cachedToken;
  int? _tokenExpMs;

  // Normaliza acentos y convierte a minúsculas para la búsqueda.
  static String _norm(String s) {
    const map = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
      'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U', 'Ñ': 'N',
    };
    return s.split('').map((c) => map[c] ?? c).join().toLowerCase();
  }

  Future<String> _getToken() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_cachedToken != null &&
        _tokenExpMs != null &&
        now < _tokenExpMs! - 120000) {
      return _cachedToken!;
    }

    final resp = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.products.authToken,
      queryParameters: {'user_type': 'agricultor_experimentado'},
    );

    final token = resp.data?['access_token'] as String?;
    if (token == null) {
      throw const ServerException(
          message: 'No se obtuvo token del servicio de productos');
    }

    // Parsear exp del JWT para saber cuándo expira.
    try {
      final parts = token.split('.');
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final exp =
          (jsonDecode(payload) as Map<String, dynamic>)['exp'] as int?;
      _tokenExpMs = exp != null ? exp * 1000 : now + 3600000;
    } catch (_) {
      _tokenExpMs = now + 3600000;
    }

    return _cachedToken = token;
  }

  @override
  Future<ProductsResponse> getRecommendedProducts({
    required String disease,
    String? crop,
  }) async {
    try {
      final token = await _getToken();
      final auth = {'Authorization': 'Bearer $token'};
      final normDisease = _norm(disease);
      final normCrop = crop != null && crop.isNotEmpty ? _norm(crop) : null;

      // 1. Buscar por enfermedad completa + cultivo.
      var items = await _fetchItems(normDisease, normCrop, auth);

      // 2. Si no hay resultados, buscar solo con la primera palabra de la enfermedad.
      if (items.isEmpty) {
        final firstWord = normDisease.split(' ').first;
        if (firstWord != normDisease) {
          items = await _fetchItems(firstWord, normCrop, auth);
        }
      }

      // 3. Fallback: solo por cultivo.
      if (items.isEmpty && normCrop != null) {
        items = await _fetchItems(null, normCrop, auth);
      }

      final products = items
          .map(ProductModel.fromJson)
          .where((p) => p.name.isNotEmpty)
          .toList();

      final productType =
          items.isNotEmpty ? items.first['product_type'] as String? : null;

      return (productType: productType, products: products);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] as String? ??
            e.message ??
            'Error al obtener productos recomendados',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Error inesperado: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchItems(
    String? disease,
    String? crop,
    Map<String, String> authHeader,
  ) async {
    final params = <String, dynamic>{'per_page': 8};
    if (disease != null && disease.isNotEmpty) params['disease'] = disease;
    if (crop != null && crop.isNotEmpty) params['crop'] = crop;

    final resp = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.products.products,
      queryParameters: params,
      options: Options(headers: authHeader),
    );

    return ((resp.data?['items'] as List<dynamic>?) ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
