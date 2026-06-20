import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';
import '../repositories/aprendiz_diagnosis_repository.dart';

class AnalyzeCropAprendizUseCase implements UseCase<DiagnosisEntity, AnalyzeCropAprendizParams> {
  final AprendizDiagnosisRepository repository;

  AnalyzeCropAprendizUseCase(this.repository);

  @override
  Future<Either<Failure, DiagnosisEntity>> call(AnalyzeCropAprendizParams params) {
    return repository.analyzeCrop(imagePath: params.imagePath, description: params.description);
  }
}

class AnalyzeCropAprendizParams extends Equatable {
  final String imagePath;
  final String? description;

  const AnalyzeCropAprendizParams({required this.imagePath, this.description});

  @override
  List<Object?> get props => [imagePath, description];
}
