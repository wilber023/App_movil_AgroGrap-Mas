import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/aprendiz_profile_repository.dart';

class SetOfflineModeUseCase implements UseCase<Unit, SetOfflineModeParams> {
  final AprendizProfileRepository repository;

  SetOfflineModeUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(SetOfflineModeParams params) {
    return repository.setOfflineModeEnabled(params.enabled);
  }
}

class SetOfflineModeParams {
  final bool enabled;
  const SetOfflineModeParams({required this.enabled});
}
