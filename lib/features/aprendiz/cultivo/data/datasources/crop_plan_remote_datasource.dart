import 'package:dio/dio.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../models/crop_plan_model.dart';
import '../../domain/entities/crop_health_entity.dart';
import '../models/crop_activity_model.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../../domain/entities/crop_practice_location.dart';

abstract class CropPlanRemoteDataSource {
  Future<CropPlanModel> getSavedCropPlan();
  Future<CropPlanModel> registerCropPlan({
    required String cultivoId,
    required DateTime startDate,
    required CropPracticeLocation practiceLocation,
  });
  Future<CropHealthEntity> getCropHealthIndicator();
  Future<CropActivityModel> updateActivityStatus(String activityId, ActivityStatus status, String? reason);
  Future<String> getSowingPlanText({
    required String cropName,
    required CropPracticeLocation practiceLocation,
  });
}

class CropPlanRemoteDataSourceImpl implements CropPlanRemoteDataSource {
  final ApiClient apiClient;
  final Dio cultivosClient;
  final Dio llmClient;

  CropPlanRemoteDataSourceImpl({
    required this.apiClient,
    required this.cultivosClient,
    required this.llmClient,
  });

  // ---------------------------------------------------------------------------
  // Cultivo de práctica -- microservicio de Cultivos (POST/GET /selecciones)
  // Ver README_FRONTEND_APRENDIZ_SIEMBRA.md, sección 4.
  // ---------------------------------------------------------------------------

  @override
  Future<CropPlanModel> getSavedCropPlan() async {
    try {
      final response = await cultivosClient.get(ApiEndpoints.selecciones.myList);
      final items = _parseListResponse(response.data);
      if (items.isEmpty) {
        throw const ServerException(
          message: 'Aún no has registrado un cultivo de práctica.',
          statusCode: 404,
        );
      }
      // El aprendiz solo gestiona un cultivo de práctica a la vez; el
      // listado viene ordenado del más reciente al más antiguo.
      return CropPlanModel.fromSeleccionJson(items.first);
    } on DioException catch (e) {
      throw _mapError(e);
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException(
        message: 'Error al obtener tu cultivo de práctica.',
        statusCode: null,
      );
    }
  }

  @override
  Future<CropPlanModel> registerCropPlan({
    required String cultivoId,
    required DateTime startDate,
    required CropPracticeLocation practiceLocation,
  }) async {
    try {
      final response = await cultivosClient.post(
        ApiEndpoints.selecciones.create,
        data: {
          'cultivo_id': cultivoId,
          'fecha_siembra': _formatDate(startDate),
          'lugar_practica': practiceLocation.apiValue,
        },
      );
      return CropPlanModel.fromSeleccionJson(_unwrapMap(response.data));
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw const ServerException(
        message: 'Error al registrar tu cultivo de práctica.',
        statusCode: null,
      );
    }
  }

  @override
  Future<String> getSowingPlanText({
    required String cropName,
    required CropPracticeLocation practiceLocation,
  }) async {
    try {
      final response = await llmClient.post(
        ApiEndpoints.llm.planSiembra,
        data: {
          'cultivo': cropName,
          'lugar_practica': practiceLocation.apiValue,
        },
      );
      final texto = _unwrapMap(response.data)['texto']?.toString() ?? '';
      if (texto.isEmpty) {
        throw const ServerException(
          message: 'No se pudo generar el plan de siembra.',
          statusCode: null,
        );
      }
      return texto;
    } on DioException catch (e) {
      throw _mapError(e);
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException(
        message: 'Error al generar el plan de siembra.',
        statusCode: null,
      );
    }
  }

  String _formatDate(DateTime date) => date.toIso8601String().substring(0, 10);

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map['data'] is Map) return Map<String, dynamic>.from(map['data'] as Map);
      return map;
    }
    return const {};
  }

  List<Map<String, dynamic>> _parseListResponse(dynamic data) {
    List raw = [];
    if (data is List) {
      raw = data;
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in ['data', 'items', 'selecciones', 'results']) {
        if (map[key] is List) {
          raw = map[key] as List;
          break;
        }
      }
    }
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  ServerException _mapError(DioException e) {
    if (e.response == null) {
      return ServerException(message: _networkMessage(e.type), statusCode: null);
    }
    final code = e.response!.statusCode;
    final detail = _extractDetail(e.response!.data);
    return ServerException(message: detail ?? _defaultMessage(code), statusCode: code);
  }

  String? _extractDetail(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['detail'] ?? data['error'] ?? data['message'])?.toString();
    }
    return null;
  }

  String _networkMessage(DioExceptionType type) => switch (type) {
        DioExceptionType.connectionTimeout =>
          'Sin conexión. Verifica tu red e intenta de nuevo.',
        DioExceptionType.sendTimeout =>
          'No se pudo enviar la solicitud. Verifica tu conexión.',
        DioExceptionType.receiveTimeout =>
          'El servidor tardó demasiado. Intenta de nuevo.',
        DioExceptionType.connectionError =>
          'Sin conexión a internet. Activa tu red e intenta de nuevo.',
        _ => 'No se pudo conectar al servidor de cultivos. Intenta más tarde.',
      };

  String _defaultMessage(int? code) => switch (code) {
        400 => 'Datos inválidos. Revisa el formulario.',
        401 => 'Sesión expirada. Vuelve a iniciar sesión.',
        403 => 'No tienes permisos para realizar esta acción.',
        404 => 'El cultivo seleccionado ya no está disponible.',
        422 => 'Datos inválidos. Revisa el formulario.',
        500 => 'Error interno del servidor. Intenta más tarde.',
        _ => 'Ocurrió un error inesperado. Intenta de nuevo.',
      };

  // ---------------------------------------------------------------------------
  // Salud del cultivo y actividades -- aún sin backend real confirmado
  // (ver README_FRONTEND_APRENDIZ_SIEMBRA.md, sección 7: "fuera de alcance").
  // Se mantienen sobre el microservicio de Usuarios hasta que se documenten.
  // ---------------------------------------------------------------------------

  @override
  Future<CropHealthEntity> getCropHealthIndicator() async {
    final response = await apiClient.get<CropHealthEntity>(
      ApiEndpoints.aprendiz.cropHealth,
      fromJsonT: (json) => CropHealthEntity(
        status: json['status'],
        healthyPlantsPercentage: json['healthyPlantsPercentage'],
        affectedPlantsPercentage: json['affectedPlantsPercentage'],
        lastInspectionDate: DateTime.parse(json['lastInspectionDate']),
      ),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Error al obtener salud');
    }
    return response.data!;
  }

  @override
  Future<CropActivityModel> updateActivityStatus(String activityId, ActivityStatus status, String? reason) async {
    final response = await apiClient.post<CropActivityModel>(
      ApiEndpoints.aprendiz.activityStatus(activityId),
      data: {'status': status.name, 'reason': reason},
      fromJsonT: (json) => CropActivityModel.fromJson(json),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Error al actualizar actividad');
    }
    return response.data!;
  }
}
