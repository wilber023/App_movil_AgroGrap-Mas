import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/aprendiz_profile_overview_entity.dart';
import '../repositories/aprendiz_profile_repository.dart';

class GetAprendizProfileOverviewUseCase implements UseCase<AprendizProfileOverviewEntity, NoParams> {
  final AprendizProfileRepository repository;

  GetAprendizProfileOverviewUseCase(this.repository);

  @override
  Future<Either<Failure, AprendizProfileOverviewEntity>> call(NoParams params) {
    return repository.getProfileOverview();
  }
}
