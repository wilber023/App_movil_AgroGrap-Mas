// =============================================================================
// Feature: Parcelas/Cultivos -- Fuente de Datos Remota + Caché Local
// =============================================================================
// Microservicio: http://3.217.217.227/api/v1  (Nginx puerto 80)
// Autenticación: Bearer token JWT inyectado automáticamente por AuthInterceptor.
//
// El endpoint GET /selecciones/usuario/{id}/actual requiere X-Service-Key
// (uso servidor-a-servidor) y NO acepta JWT del cliente Flutter.
// Por eso las selecciones se persisten localmente en Hive luego de cada
// POST /selecciones exitoso. getMisSelecciones() lee de esa caché.
// =============================================================================

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/cultivo_model.dart';
import '../models/seleccion_model.dart';
import '../../domain/repositories/parcel_repository.dart';

abstract interface class CultivosRemoteDataSource {
  Future<List<CultivoModel>> getCatalog();
  Future<CultivoModel> getCultivoById(int id);
  Future<List<SeleccionModel>> getMisSelecciones();
  Future<SeleccionModel> crearSeleccion(AddParcelParams params);
  Future<void> eliminarSeleccion(int seleccionId);
}

class CultivosRemoteDataSourceImpl implements CultivosRemoteDataSource {
  final Dio client;
  final TokenStorage tokenStorage;
  final Box<String> seleccionesBox;

  const CultivosRemoteDataSourceImpl({
    required this.client,
    required this.tokenStorage,
    required this.seleccionesBox,
  });

  // ---------------------------------------------------------------------------
  // Helpers: user ID desde JWT + claves de Hive
  // ---------------------------------------------------------------------------

  Future<String> _getUserId() async {
    try {
      final token = await tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) return '';
      final parts = token.split('.');
      if (parts.length != 3) return '';
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = json.decode(payload) as Map<String, dynamic>;
      return map['sub']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _hiveKey(String userId, int seleccionId) => 'sel_${userId}_$seleccionId';

  String _userPrefix(String userId) => 'sel_${userId}_';

  // ---------------------------------------------------------------------------
  // Catálogo de cultivos — GET /cultivos
  // ---------------------------------------------------------------------------

  @override
  Future<List<CultivoModel>> getCatalog() async {
    try {
      final response = await client.get(ApiEndpoints.cultivosCatalog.catalog);
      return _parseCatalogResponse(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw ServerException(
        message: 'Error al procesar el catálogo de cultivos.',
        statusCode: null,
      );
    }
  }

  List<CultivoModel> _parseCatalogResponse(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => CultivoModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in ['items', 'cultivos', 'data', 'results']) {
        if (map[key] is List) {
          return (map[key] as List)
              .whereType<Map>()
              .map((e) => CultivoModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // Detalle de cultivo — GET /cultivos/{id}
  // ---------------------------------------------------------------------------

  @override
  Future<CultivoModel> getCultivoById(int id) async {
    try {
      final response = await client.get(ApiEndpoints.cultivosCatalog.byId(id));
      return CultivoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Listar mis selecciones — lee de Hive (caché local)
  // GET /selecciones/usuario/{id}/actual requiere X-Service-Key (uso interno),
  // así que persistimos localmente tras cada POST exitoso.
  // ---------------------------------------------------------------------------

  @override
  Future<List<SeleccionModel>> getMisSelecciones() async {
    final userId = await _getUserId();
    if (userId.isEmpty) return [];

    final prefix = _userPrefix(userId);
    final models = <SeleccionModel>[];

    for (final key in seleccionesBox.keys.whereType<String>()) {
      if (!key.startsWith(prefix)) continue;
      final raw = seleccionesBox.get(key);
      if (raw == null) continue;
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        models.add(SeleccionModel.fromJson(map));
      } catch (_) {
        // Dato corrupto — ignorar
      }
    }

    // Ordenar por seleccionId descendente (más reciente primero)
    models.sort((a, b) => b.seleccionId.compareTo(a.seleccionId));
    return models;
  }

  // ---------------------------------------------------------------------------
  // Registrar parcela — POST /selecciones + guardar en Hive
  // ---------------------------------------------------------------------------

  @override
  Future<SeleccionModel> crearSeleccion(AddParcelParams params) async {
    final body = <String, dynamic>{
      'cultivo_id': params.cultivoId,
      'nombre_parcela': params.nombreParcela,
      'area_ha': params.areaHa,
      'unidad_area': params.unidadArea,
      'region': params.region,
      'fecha_siembra': params.fechaSiembra.toIso8601String().substring(0, 10),
      if (params.terrenoTipo != null) 'terreno_tipo': params.terrenoTipo,
      if (params.sueloCondiciones != null && params.sueloCondiciones!.isNotEmpty)
        'suelo_condiciones': params.sueloCondiciones,
      if (params.malezaTipos != null && params.malezaTipos!.isNotEmpty)
        'maleza_tipos': params.malezaTipos,
    };

    try {
      final response = await client.post(
        ApiEndpoints.selecciones.create,
        data: body,
      );
      final model = SeleccionModel.fromJson(response.data as Map<String, dynamic>);

      // Persistir en Hive para que getMisSelecciones() lo devuelva sin red
      final userId = await _getUserId();
      if (userId.isNotEmpty) {
        final key = _hiveKey(userId, model.seleccionId);
        await seleccionesBox.put(key, json.encode(model.toJson()));
      }

      return model;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Eliminar parcela — DELETE /selecciones/{id} + borrar de Hive
  // ---------------------------------------------------------------------------

  @override
  Future<void> eliminarSeleccion(int seleccionId) async {
    try {
      await client.delete(ApiEndpoints.selecciones.byId(seleccionId));
    } on DioException catch (e) {
      // Si el backend devuelve 404, la selección ya no existe — borrar local
      if (e.response?.statusCode != 404) throw _mapError(e);
    }

    // Borrar de Hive independientemente del resultado en red
    final userId = await _getUserId();
    if (userId.isNotEmpty) {
      await seleccionesBox.delete(_hiveKey(userId, seleccionId));
    }
  }

  // ---------------------------------------------------------------------------
  // Mapeo de errores Dio → ServerException
  // ---------------------------------------------------------------------------

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
        DioExceptionType.connectionTimeout => 'Sin conexión. Verifica tu red e intenta de nuevo.',
        DioExceptionType.sendTimeout => 'No se pudo enviar la solicitud. Verifica tu conexión.',
        DioExceptionType.receiveTimeout => 'El servidor tardó demasiado. Intenta de nuevo.',
        DioExceptionType.connectionError => 'Sin conexión a internet. Activa tu red e intenta de nuevo.',
        _ => 'No se pudo conectar al servidor de cultivos. Intenta más tarde.',
      };

  String _defaultMessage(int? code) => switch (code) {
        400 => 'Datos inválidos. Revisa el formulario.',
        401 => 'Sesión expirada. Vuelve a iniciar sesión.',
        403 => 'No tienes permisos para realizar esta acción.',
        404 => 'Recurso no encontrado.',
        422 => 'Datos inválidos. Revisa el formulario.',
        500 => 'Error interno del servidor. Intenta más tarde.',
        _ => 'Ocurrió un error inesperado. Intenta de nuevo.',
      };
}
