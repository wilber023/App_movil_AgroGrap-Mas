import 'package:dio/dio.dart';
import 'api_exceptions.dart';
import 'api_response.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    return _request(() => _dio.get(path, queryParameters: queryParameters), fromJsonT);
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJsonT,
  }) async {
    return _request(() => _dio.post(path, data: data), fromJsonT);
  }

  Future<ApiResponse<T>> _request<T>(
    Future<Response> Function() request,
    T Function(dynamic)? fromJsonT,
  ) async {
    try {
      final response = await request();
      if (response.data is Map<String, dynamic>) {
        return ApiResponse<T>.fromJson(response.data as Map<String, dynamic>, fromJsonT);
      }
      return ApiResponse<T>(success: true, data: response.data as T?);
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['error'] ?? e.message;
        
        if (statusCode == 401) {
          throw UnauthorizedException(message: message.toString());
        } else if (statusCode == 400) {
          throw ValidationException(message: message.toString());
        } else if (statusCode != null && statusCode >= 500) {
          throw ServerException(message: message.toString());
        }
        throw NetworkException(message: message.toString(), statusCode: statusCode);
      } else {
        throw NetworkException(message: 'Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw NetworkException(message: 'Error inesperado: $e');
    }
  }
}
