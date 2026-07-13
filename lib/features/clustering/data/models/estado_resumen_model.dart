import '../../domain/entities/estado_resumen_entity.dart';

class EstadoResumenModel extends EstadoResumenEntity {
  const EstadoResumenModel({
    required super.estado,
    required super.campanias,
    required super.superficieHa,
    required super.productores,
    required super.campaniaDominante,
    required super.cultivoDominante,
  });

  factory EstadoResumenModel.fromJson(Map<String, dynamic> json) {
    return EstadoResumenModel(
      estado: json['estado'] as String? ?? '',
      campanias: (json['campanias'] as num?)?.toInt() ?? 0,
      superficieHa: (json['superficie_ha'] as num?)?.toDouble() ?? 0.0,
      productores: (json['productores'] as num?)?.toInt() ?? 0,
      campaniaDominante: json['campania_dominante'] as String? ?? '',
      cultivoDominante: json['cultivo_dominante'] as String? ?? '',
    );
  }
}

class MapaCampaniasModel extends MapaCampaniasEntity {
  const MapaCampaniasModel({
    required super.totalCampanias,
    required super.estados,
  });

  factory MapaCampaniasModel.fromJson(Map<String, dynamic> json) {
    final rawEstados = json['estados'] as List<dynamic>? ?? [];
    return MapaCampaniasModel(
      totalCampanias: (json['total_campanias'] as num?)?.toInt() ?? 0,
      estados: rawEstados
          .whereType<Map>()
          .map((e) => EstadoResumenModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
