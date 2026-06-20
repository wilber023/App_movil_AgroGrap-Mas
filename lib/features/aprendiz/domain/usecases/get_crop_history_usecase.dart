import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/crop_event_entity.dart';
import '../repositories/crop_history_repository.dart';

class GetCropHistoryUseCase implements UseCase<List<CropEventEntity>, NoParams> {
  final CropHistoryRepository repository;

  GetCropHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<CropEventEntity>>> call(NoParams params) async {
    final result = await repository.getCropHistory();
    
    return result.fold(
      (failure) => Left(failure),
      (history) {
        // Ordenamos por fecha descendente como indica el requerimiento
        final sortedHistory = List<CropEventEntity>.from(history)
          ..sort((a, b) => b.date.compareTo(a.date));
        return Right(sortedHistory);
      },
    );
  }
}
