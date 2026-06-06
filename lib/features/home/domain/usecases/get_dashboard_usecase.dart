import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dashboard_entity.dart';
import '../repositories/home_repository.dart';

class GetDashboardUseCase implements UseCase<DashboardEntity, NoParams> {
  final HomeRepository repository;
  const GetDashboardUseCase(this.repository);

  @override
  Future<Either<Failure, DashboardEntity>> call(NoParams params) {
    return repository.getDashboard();
  }
}
