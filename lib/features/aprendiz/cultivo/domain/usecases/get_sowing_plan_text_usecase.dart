import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/crop_practice_location.dart';
import '../repositories/crop_plan_repository.dart';

class GetSowingPlanTextParams extends Equatable {
  final String cropName;
  final CropPracticeLocation practiceLocation;

  const GetSowingPlanTextParams({
    required this.cropName,
    required this.practiceLocation,
  });

  @override
  List<Object?> get props => [cropName, practiceLocation];
}

class GetSowingPlanTextUseCase implements UseCase<String, GetSowingPlanTextParams> {
  final CropPlanRepository repository;

  GetSowingPlanTextUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(GetSowingPlanTextParams params) {
    return repository.getSowingPlanText(
      cropName: params.cropName,
      practiceLocation: params.practiceLocation,
    );
  }
}
