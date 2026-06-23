import '../../domain/entities/parcel_entity.dart';

class SeleccionModel extends ParcelEntity {
  const SeleccionModel({
    required super.id,
    required super.seleccionId,
    required super.cultivoId,
    required super.name,
    required super.cropName,
    required super.areaSize,
    required super.areaUnit,
    required super.region,
    super.fechaSiembra,
    required super.status,
    super.lastDiagnosisAt,
    required super.stageName,
    required super.stageProgress,
    required super.stageIndex,
  });

  factory SeleccionModel.fromJson(Map<String, dynamic> json) {
    final cultivoNombre = _str(json, ['cultivo_nombre', 'cultivoNombre', 'nombre']) ?? 'Sin cultivo';
    final nombreParcela = _str(json, ['nombre_parcela', 'nombreParcela']) ?? cultivoNombre;
    final rawEtapa = _str(json, ['etapa_fenologica', 'etapaFenologica', 'currentStage']) ?? 'Siembra';
    final progreso = (_num(json, ['progreso_etapa', 'progresoEtapa', 'progressPercentage']) ?? 0.0) / 100.0;
    final estado = _str(json, ['estado_salud', 'estadoSalud', 'status']) ?? 'Sin diagnostico';
    final rawFechaSiembra = _str(json, ['fecha_siembra', 'fechaSiembra', 'startDate']);

    return SeleccionModel(
      id: json['id'].toString(),
      seleccionId: (json['id'] as num).toInt(),
      cultivoId: (json['cultivo_id'] ?? json['cultivoId'] ?? 0) as int,
      name: nombreParcela,
      cropName: cultivoNombre,
      areaSize: (_num(json, ['area_ha', 'areaHa']) ?? 0.0),
      areaUnit: _str(json, ['unidad_area', 'unidadArea']) ?? 'ha',
      region: _str(json, ['region']) ?? '',
      fechaSiembra: rawFechaSiembra != null ? DateTime.tryParse(rawFechaSiembra) : null,
      status: _mapEstado(estado),
      stageName: _mapEtapa(rawEtapa),
      stageProgress: progreso.clamp(0.0, 1.0),
      stageIndex: _stageIndex(_mapEtapa(rawEtapa)),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': seleccionId,
        'cultivo_id': cultivoId,
        'nombre_parcela': name,
        'cultivo_nombre': cropName,
        'area_ha': areaSize,
        'unidad_area': areaUnit,
        'region': region,
        'fecha_siembra': fechaSiembra?.toIso8601String(),
        'etapa_fenologica': stageName,
        'progreso_etapa': (stageProgress * 100).round(),
        'estado_salud': status,
      };

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String? _str(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json.containsKey(k) && json[k] != null) return json[k].toString();
    }
    return null;
  }

  static double? _num(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json.containsKey(k) && json[k] != null) {
        return (json[k] as num).toDouble();
      }
    }
    return null;
  }

  static String _mapEstado(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('alerta') || lower.contains('alert')) return 'Alerta';
    if (lower.contains('seguimiento') || lower.contains('follow')) return 'Seguimiento';
    if (lower.contains('saludable') || lower.contains('healthy')) return 'Saludable';
    return 'Sin diagnostico';
  }

  static String _mapEtapa(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('siembra') || lower.contains('seed') || lower.contains('emerg')) return 'Siembra';
    if (lower.contains('vegeta') || lower.contains('growth')) return 'Vegetativo';
    if (lower.contains('flora') || lower.contains('flower') || lower.contains('bloom')) return 'Floracion';
    if (lower.contains('cosech') || lower.contains('harvest')) return 'Cosecha';
    return raw;
  }

  static int _stageIndex(String etapa) {
    switch (etapa) {
      case 'Siembra':
        return 0;
      case 'Vegetativo':
        return 1;
      case 'Floracion':
        return 2;
      case 'Cosecha':
        return 3;
      default:
        return 0;
    }
  }
}
