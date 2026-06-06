import 'package:dio/dio.dart';
import '../models/dashboard_model.dart';

abstract interface class HomeRemoteDataSource {
  Future<DashboardModel> getDashboard();
  Future<List<AlertModel>> getAlerts();
  Future<WeatherModel> getWeather();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio client;
  const HomeRemoteDataSourceImpl({required this.client});

  @override
  Future<DashboardModel> getDashboard() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return DashboardModel(
      userName: 'Wil',
      totalParcels: 12,
      healthyParcels: 9,
      atRiskParcels: 3,
      pendingTreatments: 2,
      completedDiagnosis: 15,
      weather: const WeatherModel(
        temperature: 24,
        humidity: 60,
        condition: 'Soleado',
        location: 'Valle Central',
      ),
      recentAlerts: [
        AlertModel(
          id: '1',
          title: 'Tizon tardio',
          description: 'Riesgo alto detectado en la parcela Norte',
          severity: 'alta',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        AlertModel(
          id: '2',
          title: 'Gusano cogollero',
          description: 'Recordatorio: 2da aplicacion manana',
          severity: 'media',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    );
  }

  @override
  Future<List<AlertModel>> getAlerts() async {
    return [];
  }

  @override
  Future<WeatherModel> getWeather() async {
    return const WeatherModel(
      temperature: 24,
      humidity: 60,
      condition: 'Soleado',
      location: 'Valle Central',
    );
  }
}
