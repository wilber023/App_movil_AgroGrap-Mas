import 'package:equatable/equatable.dart';

/// Nivel de riesgo fitosanitario/epidemiologico para la region del usuario.
enum PhytosanitaryAlertLevel { none, low, moderate, high }

/// Alerta fitosanitaria de la region. Alimentada por el feature de
/// clustering (`GET /api/v1/alertas`, ver `AprendizHomeRepositoryImpl`) --
/// `none` cuando no hay alerta activa para el estado del usuario o cuando
/// la consulta falla, nunca datos inventados.
class PhytosanitaryAlertEntity extends Equatable {
  final PhytosanitaryAlertLevel level;
  final String message;

  const PhytosanitaryAlertEntity({required this.level, required this.message});

  static const none = PhytosanitaryAlertEntity(
    level: PhytosanitaryAlertLevel.none,
    message: 'No existen alertas para tu región.',
  );

  @override
  List<Object?> get props => [level, message];
}
