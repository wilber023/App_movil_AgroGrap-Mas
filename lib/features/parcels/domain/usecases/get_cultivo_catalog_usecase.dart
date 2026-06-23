import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cultivo_entity.dart';
import '../repositories/parcel_repository.dart';

class GetCultivoCatalogUseCase implements UseCase<List<CultivoEntity>, NoParams> {
  final ParcelRepository repository;

  GetCultivoCatalogUseCase(this.repository);

  @override
  Future<Either<Failure, List<CultivoEntity>>> call(NoParams params) {
    return repository.getCultivoCatalog();
  }
}
