import '../../domain/entities/dashboard_entity.dart';

class DashboardModel extends DashboardEntity {
  const DashboardModel({
    required super.userName,
    required super.totalParcels,
    required super.healthyParcels,
    required super.atRiskParcels,
    required super.pendingTreatments,
    required super.completedDiagnosis,
    super.recentAlerts,
    super.weather,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      userName: json['user_name'] as String? ?? '',
      totalParcels: json['total_parcels'] as int? ?? 0,
      healthyParcels: json['healthy_parcels'] as int? ?? 0,
      atRiskParcels: json['at_risk_parcels'] as int? ?? 0,
      pendingTreatments: json['pending_treatments'] as int? ?? 0,
      completedDiagnosis: json['completed_diagnosis'] as int? ?? 0,
      recentAlerts: (json['recent_alerts'] as List<dynamic>?)
              ?.map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      weather: json['weather'] != null
          ? WeatherModel.fromJson(json['weather'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AlertModel extends AlertEntity {
  const AlertModel({
    required super.id,
    required super.title,
    required super.description,
    required super.severity,
    required super.createdAt,
    super.isRead,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'baja',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

class WeatherModel extends WeatherEntity {
  const WeatherModel({
    required super.temperature,
    required super.humidity,
    required super.condition,
    required super.location,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0,
      condition: json['condition'] as String? ?? '',
      location: json['location'] as String? ?? '',
    );
  }
}
