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
  Future<CultivoModel> getCultivoById(String id);
  Future<List<SeleccionModel>> getMisSelecciones();
  Future<SeleccionModel> crearSeleccion(AddParcelParams params);
  Future<void> eliminarSeleccion(String seleccionId);
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
  // Helpers internos
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

  String _hiveKey(String userId, String seleccionId) => 'sel_${userId}_$seleccionId';
  String _userPrefix(String userId) => 'sel_${userId}_';

  // Desenvuelve `{"data": {...}}` → devuelve el mapa interno.
  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map.containsKey('data') && map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    return {};
  }

  // Normaliza respuestas que pueden ser array o `{"data": [...]}`.
  List<Map<String, dynamic>> _parseListResponse(dynamic data) {
    List raw = [];
    if (data is List) {
      raw = data;
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final k in ['data', 'items', 'selecciones', 'results']) {
        if (map[k] is List) {
          raw = map[k] as List;
          break;
        }
      }
    }
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // Catálogo de cultivos
  // ---------------------------------------------------------------------------

  @override
  Future<List<CultivoModel>> getCatalog() async {
    try {
      final response = await client.get(ApiEndpoints.cultivosCatalog.catalog);
      return _parseCatalogResponse(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw ServerException(
          message: 'Error al procesar el catálogo de cultivos.', statusCode: null);
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
      for (final key in ['data', 'items', 'cultivos', 'results']) {
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

  @override
  Future<CultivoModel> getCultivoById(String id) async {
    try {
      final response = await client.get(ApiEndpoints.cultivosCatalog.byId(id));
      return CultivoModel.fromJson(_unwrapMap(response.data));
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Mis selecciones — GET /selecciones/mis-selecciones (JWT de usuario)
  // El servidor filtra por el `sub` del token automáticamente.
  // Devuelve datos completos: cultivo_nombre, nombre_parcela, area_ha, region, etc.
  // ---------------------------------------------------------------------------

  @override
  Future<List<SeleccionModel>> getMisSelecciones() async {
    final userId = await _getUserId();
    if (userId.isEmpty) return [];

    try {
      final response = await client.get(ApiEndpoints.selecciones.myList);
      final items = _parseListResponse(response.data);

      // Si el servidor no incluye cultivo_nombre en la respuesta,
      // se enriquece con el catálogo (GET /cultivos) para obtener el nombre.
      final needsEnrichment =
          items.any((r) => (r['cultivo_nombre']?.toString() ?? '').isEmpty);
      final catalogMap = needsEnrichment ? await _buildCatalogMap() : <String, String>{};

      final models = <SeleccionModel>[];
      for (final raw in items) {
        try {
          final cultivoId = raw['cultivo_id']?.toString() ?? '';
          final serverNombre = raw['cultivo_nombre']?.toString() ?? '';
          // Enriquece con el catálogo si el servidor no devuelve cultivo_nombre
          final enriched = (serverNombre.isEmpty && catalogMap.containsKey(cultivoId))
              ? <String, dynamic>{...raw, 'cultivo_nombre': catalogMap[cultivoId]}
              : Map<String, dynamic>.from(raw);

          final model = SeleccionModel.fromJson(enriched);
          if (model.seleccionId.isEmpty) continue;
          // Actualiza caché local (offline fallback)
          await seleccionesBox.put(
              _hiveKey(userId, model.seleccionId), json.encode(model.toJson()));
          models.add(model);
        } catch (_) {}
      }

      models.sort((a, b) => b.seleccionId.compareTo(a.seleccionId));
      return models;
    } catch (_) {
      return _readFromHive(userId);
    }
  }

  Future<Map<String, String>> _buildCatalogMap() async {
    try {
      final response = await client.get(ApiEndpoints.cultivosCatalog.catalog);
      final cultivos = _parseCatalogResponse(response.data);
      return {for (final c in cultivos) c.id: c.nombre};
    } catch (_) {
      return {};
    }
  }

  List<SeleccionModel> _readFromHive(String userId) {
    final prefix = _userPrefix(userId);
    final models = <SeleccionModel>[];
    for (final key in seleccionesBox.keys.whereType<String>()) {
      if (!key.startsWith(prefix)) continue;
      final raw = seleccionesBox.get(key);
      if (raw == null) continue;
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        final model = SeleccionModel.fromJson(map);
        if (model.seleccionId.isEmpty) continue;
        models.add(model);
      } catch (_) {}
    }
    models.sort((a, b) => b.seleccionId.compareTo(a.seleccionId));
    return models;
  }

  // ---------------------------------------------------------------------------
  // Crear selección — POST /selecciones
  // El servidor ahora persiste todos los campos y los devuelve en la respuesta,
  // incluyendo cultivo_nombre → no se necesita merge manual.
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
      final response = await client.post(ApiEndpoints.selecciones.create, data: body);
      final serverData = _unwrapMap(response.data);

      // Si el servidor no devuelve cultivo_nombre, se usa el valor del formulario
      // para que la tarjeta muestre el nombre correcto inmediatamente.
      if ((serverData['cultivo_nombre']?.toString() ?? '').isEmpty) {
        serverData['cultivo_nombre'] = params.cultivoNombre;
      }
      if ((serverData['nombre_parcela']?.toString() ?? '').isEmpty) {
        serverData['nombre_parcela'] = params.nombreParcela;
      }
      if ((serverData['area_ha'] == null)) {
        serverData['area_ha'] = params.areaHa;
      }
      if ((serverData['region']?.toString() ?? '').isEmpty) {
        serverData['region'] = params.region;
      }
      serverData.putIfAbsent('etapa_fenologica', () => 'Siembra');
      serverData.putIfAbsent('progreso_etapa', () => 0);
      serverData.putIfAbsent('estado_salud', () => 'Sin diagnostico');

      final model = SeleccionModel.fromJson(serverData);

      // Guarda en Hive como caché offline
      final userId = await _getUserId();
      if (userId.isNotEmpty && model.seleccionId.isNotEmpty) {
        await seleccionesBox.put(
            _hiveKey(userId, model.seleccionId), json.encode(model.toJson()));
      }

      return model;
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw ServerException(
          message: 'Error al guardar la parcela.', statusCode: null);
    }
  }

  // ---------------------------------------------------------------------------
  // Eliminar selección — DELETE /selecciones/{id}
  // ---------------------------------------------------------------------------

  @override
  Future<void> eliminarSeleccion(String seleccionId) async {
    try {
      await client.delete(ApiEndpoints.selecciones.byId(seleccionId));
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) throw _mapError(e);
    }

    final userId = await _getUserId();
    if (userId.isNotEmpty) {
      await seleccionesBox.delete(_hiveKey(userId, seleccionId));
    }
  }

  // ---------------------------------------------------------------------------
  // Mapeo de errores Dio
  // ---------------------------------------------------------------------------

  ServerException _mapError(DioException e) {
    if (e.response == null) {
      return ServerException(
          message: _networkMessage(e.type), statusCode: null);
    }
    final code = e.response!.statusCode;
    final detail = _extractDetail(e.response!.data);
    return ServerException(
        message: detail ?? _defaultMessage(code), statusCode: code);
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
        404 => 'Recurso no encontrado.',
        422 => 'Datos inválidos. Revisa el formulario.',
        500 => 'Error interno del servidor. Intenta más tarde.',
        _ => 'Ocurrió un error inesperado. Intenta de nuevo.',
      };
}
