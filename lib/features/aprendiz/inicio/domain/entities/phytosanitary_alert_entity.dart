import 'package:equatable/equatable.dart';

/// Nivel de riesgo fitosanitario/epidemiologico para la region del usuario.
enum PhytosanitaryAlertLevel { none, low, moderate, high }

/// Alerta fitosanitaria de la region. Todavia no existe un endpoint real
/// para esto (ver `PhytosanitaryAlertLocalDataSource`) — mientras tanto se
/// muestra siempre el estado neutral real `PhytosanitaryAlertLevel.none`,
/// nunca datos inventados.
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
