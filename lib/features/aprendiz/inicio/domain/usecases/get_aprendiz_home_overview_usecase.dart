import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/aprendiz_home_overview_entity.dart';
import '../repositories/aprendiz_home_repository.dart';

class GetAprendizHomeOverviewUseCase implements UseCase<AprendizHomeOverviewEntity, NoParams> {
  final AprendizHomeRepository repository;

  GetAprendizHomeOverviewUseCase(this.repository);

  @override
  Future<Either<Failure, AprendizHomeOverviewEntity>> call(NoParams params) {
    return repository.getHomeOverview();
  }
}
