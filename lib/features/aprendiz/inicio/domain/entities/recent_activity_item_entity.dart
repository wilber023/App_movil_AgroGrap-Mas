import 'package:equatable/equatable.dart';

/// Tipo de evento reciente mostrado en "Actividad reciente".
enum RecentActivityType { diagnosis, cropRegistered, activityCompleted }

/// Item de la lista "Actividad reciente" (maximo 3, ordenados por fecha
/// descendente) — ver `AprendizHomeRepositoryImpl`, que los arma
/// combinando datos reales de Cultivo y Diagnostico.
class RecentActivityItemEntity extends Equatable {
  final RecentActivityType type;
  final String label;
  final String? detail;
  final DateTime date;

  const RecentActivityItemEntity({
    required this.type,
    required this.label,
    this.detail,
    required this.date,
  });

  @override
  List<Object?> get props => [type, label, detail, date];
}
