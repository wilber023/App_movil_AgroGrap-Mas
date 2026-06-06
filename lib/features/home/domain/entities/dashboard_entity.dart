import 'package:equatable/equatable.dart';

class DashboardEntity extends Equatable {
  final String userName;
  final int totalParcels;
  final int healthyParcels;
  final int atRiskParcels;
  final int pendingTreatments;
  final int completedDiagnosis;
  final List<AlertEntity> recentAlerts;
  final WeatherEntity? weather;

  const DashboardEntity({
    required this.userName,
    required this.totalParcels,
    required this.healthyParcels,
    required this.atRiskParcels,
    required this.pendingTreatments,
    required this.completedDiagnosis,
    this.recentAlerts = const [],
    this.weather,
  });

  double get healthPercentage =>
      totalParcels > 0 ? healthyParcels / totalParcels : 0.0;

  @override
  List<Object?> get props => [
        userName, totalParcels, healthyParcels, atRiskParcels,
        pendingTreatments, completedDiagnosis, recentAlerts, weather,
      ];
}

class AlertEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String severity; // alta, media, baja
  final DateTime createdAt;
  final bool isRead;

  const AlertEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.createdAt,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [id, title, severity, createdAt, isRead];
}

class WeatherEntity extends Equatable {
  final double temperature;
  final double humidity;
  final String condition;
  final String location;

  const WeatherEntity({
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.location,
  });

  @override
  List<Object?> get props => [temperature, humidity, condition, location];
}
