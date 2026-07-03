import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/parcel_entity.dart';
import '../repositories/parcel_repository.dart';

class GetParcelsUseCase implements UseCase<List<ParcelEntity>, NoParams> {
  final ParcelRepository repository;

  GetParcelsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ParcelEntity>>> call(NoParams params) async {
    return await repository.getParcels();
  }
}
