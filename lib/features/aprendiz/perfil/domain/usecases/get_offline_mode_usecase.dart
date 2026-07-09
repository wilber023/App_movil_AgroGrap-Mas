import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/aprendiz_profile_repository.dart';

class GetOfflineModeUseCase implements UseCase<bool, NoParams> {
  final AprendizProfileRepository repository;

  GetOfflineModeUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.getOfflineModeEnabled();
  }
}
