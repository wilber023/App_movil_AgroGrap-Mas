// =============================================================================
// Feature: Auth -- Fuente de Datos Local (Hive)
// =============================================================================
// Capa: Data / DataSources
// Regla: Maneja la persistencia local del usuario autenticado.
//        Soporta la filosofia "Offline-First" del Design System:
//        "tus datos se guardan localmente".
//        Lanza [CacheException] si la lectura/escritura falla.
// =============================================================================

import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Contrato de la fuente de datos local de autenticacion.
abstract interface class AuthLocalDataSource {
  /// Recupera el ultimo usuario autenticado del cache.
  /// Lanza [CacheException] si no hay datos almacenados.
  Future<UserModel> getLastUser();

  /// Almacena el usuario autenticado en el cache local.
  Future<void> cacheUser(UserModel user);

  /// Elimina el usuario del cache (usado en logout).
  Future<void> clearCache();

  /// Verifica si hay un usuario cacheado sin lanzar excepciones.
  Future<bool> hasCachedUser();
}

/// Implementacion concreta de [AuthLocalDataSource] usando Hive.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box<String> authBox;

  /// Clave de almacenamiento para los datos del usuario.
  static const String _cachedUserKey = 'CACHED_USER';

  const AuthLocalDataSourceImpl({required this.authBox});

  @override
  Future<UserModel> getLastUser() async {
    final jsonString = authBox.get(_cachedUserKey);

    if (jsonString == null || jsonString.isEmpty) {
      throw const CacheException(
        message: 'No hay sesion almacenada localmente.',
      );
    }

    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(jsonMap);
    } catch (e) {
      throw CacheException(
        message: 'Error al leer datos del cache: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final jsonString = json.encode(user.toCacheJson());
      await authBox.put(_cachedUserKey, jsonString);
    } catch (e) {
      throw CacheException(
        message: 'Error al guardar datos en cache: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await authBox.delete(_cachedUserKey);
    } catch (e) {
      throw CacheException(
        message: 'Error al limpiar el cache: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> hasCachedUser() async {
    return authBox.containsKey(_cachedUserKey);
  }
}
