import '../../domain/entities/alerta_epidemiologica_entity.dart';

class AlertaEpidemiologicaModel extends AlertaEpidemiologicaEntity {
  const AlertaEpidemiologicaModel({
    required super.hayAlerta,
    required super.estado,
    required super.mensaje,
    super.campaniaDominante,
    super.plagaDominante,
    super.cultivoDominante,
    super.campanias,
    super.superficieHa,
  });

  factory AlertaEpidemiologicaModel.fromJson(Map<String, dynamic> json) {
    return AlertaEpidemiologicaModel(
      hayAlerta: json['hay_alerta'] as bool? ?? false,
      estado: json['estado'] as String? ?? '',
      mensaje: json['mensaje'] as String? ?? '',
      campaniaDominante: json['campania_dominante'] as String?,
      plagaDominante: json['plaga_dominante'] as String?,
      cultivoDominante: json['cultivo_dominante'] as String?,
      campanias: (json['campanias'] as num?)?.toInt(),
      superficieHa: (json['superficie_ha'] as num?)?.toDouble(),
    );
  }
}
