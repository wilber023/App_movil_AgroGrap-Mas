import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/aprendiz_profile_settings_model.dart';

/// Persistencia local de los ajustes del Perfil (hoy: modo sin conexion).
/// El resto del contenido del Perfil (progreso, estadisticas, objetivos,
/// recomendacion) se calcula en [AprendizProfileRepositoryImpl] a partir de
/// datos reales de otros modulos — esta clase solo lee/escribe ajustes.
abstract class AprendizProfileLocalDataSource {
  Future<bool> getOfflineModeEnabled();
  Future<void> setOfflineModeEnabled(bool enabled);
}

class AprendizProfileLocalDataSourceImpl implements AprendizProfileLocalDataSource {
  final Box<String> box;
  static const _settingsKey = 'APRENDIZ_PROFILE_SETTINGS';

  AprendizProfileLocalDataSourceImpl({required this.box});

  @override
  Future<bool> getOfflineModeEnabled() async {
    final jsonString = box.get(_settingsKey);
    if (jsonString == null) {
      return AprendizProfileSettingsModel.defaultSettings.offlineModeEnabled;
    }
    return AprendizProfileSettingsModel.fromJson(jsonDecode(jsonString)).offlineModeEnabled;
  }

  @override
  Future<void> setOfflineModeEnabled(bool enabled) async {
    await box.put(
      _settingsKey,
      jsonEncode(AprendizProfileSettingsModel(offlineModeEnabled: enabled).toJson()),
    );
  }
}
