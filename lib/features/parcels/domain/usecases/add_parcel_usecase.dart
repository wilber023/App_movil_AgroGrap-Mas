import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/parcel_entity.dart';
import '../repositories/parcel_repository.dart';

class AddParcelUseCase implements UseCase<ParcelEntity, AddParcelParams> {
  final ParcelRepository repository;

  AddParcelUseCase(this.repository);

  @override
  Future<Either<Failure, ParcelEntity>> call(AddParcelParams params) {
    return repository.addParcel(params);
  }
}
