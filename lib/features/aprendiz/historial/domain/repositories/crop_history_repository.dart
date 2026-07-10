import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/crop_event_entity.dart';

abstract class CropHistoryRepository {
  Future<Either<Failure, List<CropEventEntity>>> getCropHistory();
}
