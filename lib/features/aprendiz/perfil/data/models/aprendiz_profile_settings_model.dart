/// Ajustes locales del Perfil del Aprendiz (persistidos en Hive). Hoy solo
/// contiene el modo sin conexion, pero queda preparado para sumar mas
/// preferencias (notificaciones, idioma) sin cambiar la forma de acceso.
class AprendizProfileSettingsModel {
  final bool offlineModeEnabled;

  const AprendizProfileSettingsModel({required this.offlineModeEnabled});

  static const defaultSettings = AprendizProfileSettingsModel(offlineModeEnabled: true);

  factory AprendizProfileSettingsModel.fromJson(Map<String, dynamic> json) {
    return AprendizProfileSettingsModel(
      offlineModeEnabled: json['offlineModeEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {'offlineModeEnabled': offlineModeEnabled};
}
