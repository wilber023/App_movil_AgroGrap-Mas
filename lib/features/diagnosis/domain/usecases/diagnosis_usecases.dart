import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/diagnosis_entity.dart';
import '../repositories/diagnosis_repository.dart';

class AnalyzeCropUseCase implements UseCase<DiagnosisEntity, AnalyzeCropParams> {
  final DiagnosisRepository repository;
  const AnalyzeCropUseCase(this.repository);

  @override
  Future<Either<Failure, DiagnosisEntity>> call(AnalyzeCropParams params) {
    return repository.analyzeCrop(imagePath: params.imagePath);
  }
}

class AnalyzeCropParams extends Equatable {
  final String imagePath;
  const AnalyzeCropParams({required this.imagePath});

  @override
  List<Object?> get props => [imagePath];
}

class GetDiagnosisHistoryUseCase
    implements UseCase<List<DiagnosisEntity>, NoParams> {
  final DiagnosisRepository repository;
  const GetDiagnosisHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<DiagnosisEntity>>> call(NoParams params) {
    return repository.getHistory();
  }
}
