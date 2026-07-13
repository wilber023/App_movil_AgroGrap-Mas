import 'package:dio/dio.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/agenda_activity_entity.dart';
import '../models/agenda_activity_model.dart';
import '../models/agenda_overview_model.dart';

class GenerarAgendaParams {
  final String cultivo;
  final String? enfermedad;
  final String tratamiento;
  final String? prevencion;
  final String? currentStage;

  const GenerarAgendaParams({
    required this.cultivo,
    this.enfermedad,
    required this.tratamiento,
    this.prevencion,
    this.currentStage,
  });

  Map<String, dynamic> toJson() => {
        'cultivo': cultivo,
        if (enfermedad != null && enfermedad!.isNotEmpty) 'enfermedad': enfermedad,
        'tratamiento': tratamiento,
        if (prevencion != null && prevencion!.isNotEmpty) 'prevencion': prevencion,
        if (currentStage != null && currentStage!.isNotEmpty) 'currentStage': currentStage,
      };
}

/// Fuente remota del modulo Agenda (`http://52.1.110.21:8000/api/v1/{rol}/agenda/...`,
/// backend real en produccion, verificado con curl -- ver
/// agenda_backend_implementacion.md). `{rol}` se recibe por parametro en
/// cada metodo: una sola instancia sirve tanto a Agricultor como a Aprendiz,
/// sin duplicar la logica de red/parseo/errores.
abstract interface class AgendaRemoteDataSource {
  Future<AgendaOverviewModel> generar(String rol, GenerarAgendaParams params);
  Future<AgendaOverviewModel> getAgendaOverview(String rol);
  Future<AgendaActivityModel> completeActivity(String rol, String activityId);
  Future<AgendaActivityModel> postponeActivity(String rol, String activityId, String reason);
}

class AgendaRemoteDataSourceImpl implements AgendaRemoteDataSource {
  final Dio client;

  const AgendaRemoteDataSourceImpl({required this.client});

  @override
  Future<AgendaOverviewModel> generar(String rol, GenerarAgendaParams params) async {
    try {
      final response = await client.post(
        ApiEndpoints.agenda.generar(rol),
        data: params.toJson(),
      );
      return AgendaOverviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw const ServerException(
          message: 'Error al generar la agenda.', statusCode: null);
    }
  }

  @override
  Future<AgendaOverviewModel> getAgendaOverview(String rol) async {
    try {
      final response = await client.get(ApiEndpoints.agenda.overview(rol));
      return AgendaOverviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw const ServerException(message: 'Error al obtener la agenda.', statusCode: null);
    }
  }

  @override
  Future<AgendaActivityModel> completeActivity(String rol, String activityId) async {
    try {
      final response = await client.post(
        ApiEndpoints.agenda.completeActivity(rol, activityId),
        data: {'status': AgendaActivityStatus.completed.name},
      );
      return AgendaActivityModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw const ServerException(
          message: 'Error al completar la actividad.', statusCode: null);
    }
  }

  @override
  Future<AgendaActivityModel> postponeActivity(String rol, String activityId, String reason) async {
    try {
      final response = await client.post(
        ApiEndpoints.agenda.postponeActivity(rol, activityId),
        data: {'status': AgendaActivityStatus.postponed.name, 'reason': reason},
      );
      return AgendaActivityModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw const ServerException(
          message: 'Error al posponer la actividad.', statusCode: null);
    }
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
        _ => 'No se pudo conectar con el servicio de agenda. Intenta más tarde.',
      };

  String _defaultMessage(int? code) => switch (code) {
        401 => 'Sesión expirada. Vuelve a iniciar sesión.',
        404 => 'Actividad no encontrada.',
        422 => 'Datos inválidos. Revisa la información enviada.',
        500 => 'Error interno del servidor. Intenta más tarde.',
        _ => 'Ocurrió un error inesperado. Intenta de nuevo.',
      };
}
