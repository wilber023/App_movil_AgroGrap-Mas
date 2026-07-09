import 'package:equatable/equatable.dart';

/// Contexto minimo del cultivo activo que la Agenda necesita mostrar
/// (encabezado "Mi cultivo: X" + pill "Semana N").
class AgendaCropContextEntity extends Equatable {
  final String cropName;
  final String currentStage;
  final int currentWeek;

  const AgendaCropContextEntity({
    required this.cropName,
    required this.currentStage,
    required this.currentWeek,
  });

  @override
  List<Object?> get props => [cropName, currentStage, currentWeek];
}
