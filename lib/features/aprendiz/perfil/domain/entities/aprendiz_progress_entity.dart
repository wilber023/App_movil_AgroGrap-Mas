import 'package:equatable/equatable.dart';

/// Progreso de aprendizaje del usuario dentro de AgroGraph.
///
/// [xp] y [level] se derivan de actividad real del usuario (diagnosticos
/// realizados, actividades completadas, cultivo registrado) — ver
/// `AprendizProfileLocalDataSourceImpl`. No son valores aleatorios.
class AprendizProgressEntity extends Equatable {
  final int level;
  final int xp;
  final int xpForNextLevel;
  final int streakDays;

  const AprendizProgressEntity({
    required this.level,
    required this.xp,
    required this.xpForNextLevel,
    required this.streakDays,
  });

  /// Progreso hacia el siguiente nivel, entre 0.0 y 1.0.
  double get progressToNextLevel {
    if (xpForNextLevel <= 0) return 0;
    return (xp % xpForNextLevel) / xpForNextLevel;
  }

  @override
  List<Object?> get props => [level, xp, xpForNextLevel, streakDays];
}
