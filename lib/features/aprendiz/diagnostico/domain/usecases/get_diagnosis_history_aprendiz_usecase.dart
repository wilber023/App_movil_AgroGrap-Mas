import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../agricultor/diagnosis/domain/entities/diagnosis_entity.dart';
import '../repositories/aprendiz_diagnosis_repository.dart';

class GetDiagnosisHistoryAprendizUseCase implements UseCase<List<DiagnosisEntity>, NoParams> {
  final AprendizDiagnosisRepository repository;

  GetDiagnosisHistoryAprendizUseCase(this.repository);

  @override
  Future<Either<Failure, List<DiagnosisEntity>>> call(NoParams params) {
    return repository.getHistory();
  }
}
