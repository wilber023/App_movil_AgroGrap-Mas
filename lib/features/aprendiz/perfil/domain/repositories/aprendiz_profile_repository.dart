import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../entities/aprendiz_profile_overview_entity.dart';

abstract class AprendizProfileRepository {
  Future<Either<Failure, AprendizProfileOverviewEntity>> getProfileOverview();

  Future<Either<Failure, bool>> getOfflineModeEnabled();

  Future<Either<Failure, Unit>> setOfflineModeEnabled(bool enabled);
}
