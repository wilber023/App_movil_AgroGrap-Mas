import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_entity.dart';

abstract interface class HomeRepository {
  Future<Either<Failure, DashboardEntity>> getDashboard();
  Future<Either<Failure, List<AlertEntity>>> getAlerts();
  Future<Either<Failure, WeatherEntity>> getWeather();
}
