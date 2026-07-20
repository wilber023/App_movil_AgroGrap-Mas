import 'package:equatable/equatable.dart';

/// Nivel de riesgo fitosanitario/epidemiologico para la region del usuario.
enum PhytosanitaryAlertLevel { none, low, moderate, high }

/// Alerta fitosanitaria de la region. Alimentada por la notificacion push
/// mas reciente recibida en este dispositivo (mismo historial que muestra
/// la campanita de Notificaciones, ver `AprendizHomeRepositoryImpl`) --
/// `none` cuando no hay ninguna notificacion guardada o cuando la consulta
/// falla, nunca datos inventados.
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
