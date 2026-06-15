import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/parcel_entity.dart';

abstract class ParcelRepository {
  Future<Either<Failure, List<ParcelEntity>>> getParcels();
  Future<Either<Failure, ParcelEntity>> addParcel(ParcelEntity parcel);
}
