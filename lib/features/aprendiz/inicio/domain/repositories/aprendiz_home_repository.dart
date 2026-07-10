import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../entities/aprendiz_home_overview_entity.dart';

abstract class AprendizHomeRepository {
  Future<Either<Failure, AprendizHomeOverviewEntity>> getHomeOverview();
}
