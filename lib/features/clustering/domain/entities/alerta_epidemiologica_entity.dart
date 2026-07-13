import 'package:equatable/equatable.dart';

/// Alerta epidemiológica nacional o por estado (ver `GET /api/v1/alertas`).
///
/// Los campos marcados como opcionales en el README (`AlertaResponse`) se
/// modelan como nullable aquí — el backend los omite cuando `hayAlerta` es
/// `false` (no hay campaña dominante que reportar).
class AlertaEpidemiologicaEntity extends Equatable {
  final bool hayAlerta;
  final String estado;
  final String mensaje;
  final String? campaniaDominante;
  final String? plagaDominante;
  final String? cultivoDominante;
  final int? campanias;
  final double? superficieHa;

  const AlertaEpidemiologicaEntity({
    required this.hayAlerta,
    required this.estado,
    required this.mensaje,
    this.campaniaDominante,
    this.plagaDominante,
    this.cultivoDominante,
    this.campanias,
    this.superficieHa,
  });

  @override
  List<Object?> get props => [
        hayAlerta,
        estado,
        mensaje,
        campaniaDominante,
        plagaDominante,
        cultivoDominante,
        campanias,
        superficieHa,
      ];
}
