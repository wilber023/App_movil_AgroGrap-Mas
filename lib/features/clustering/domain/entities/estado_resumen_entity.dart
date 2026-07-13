import 'package:equatable/equatable.dart';

/// Resumen de campañas fitosanitarias SENASICA para una entidad federativa
/// (ver `GET /api/v1/clustering/mapa-campanias`).
class EstadoResumenEntity extends Equatable {
  final String estado;
  final int campanias;
  final double superficieHa;
  final int productores;
  final String campaniaDominante;
  final String cultivoDominante;

  const EstadoResumenEntity({
    required this.estado,
    required this.campanias,
    required this.superficieHa,
    required this.productores,
    required this.campaniaDominante,
    required this.cultivoDominante,
  });

  @override
  List<Object?> get props => [
        estado,
        campanias,
        superficieHa,
        productores,
        campaniaDominante,
        cultivoDominante,
      ];
}

/// Mapa completo por estado, ya ordenado por superficie atendida (desc) por
/// el backend (ver `MapaCampaniasResponse`).
class MapaCampaniasEntity extends Equatable {
  final int totalCampanias;
  final List<EstadoResumenEntity> estados;

  const MapaCampaniasEntity({
    required this.totalCampanias,
    required this.estados,
  });

  @override
  List<Object?> get props => [totalCampanias, estados];
}
