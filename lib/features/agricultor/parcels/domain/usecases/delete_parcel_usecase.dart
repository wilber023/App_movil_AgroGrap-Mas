import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/parcel_repository.dart';

class DeleteParcelUseCase implements UseCase<void, DeleteParcelParams> {
  final ParcelRepository repository;

  DeleteParcelUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteParcelParams params) {
    return repository.deleteParcel(params.seleccionId);
  }
}

class DeleteParcelParams extends Equatable {
  final String seleccionId;

  const DeleteParcelParams({required this.seleccionId});

  @override
  List<Object?> get props => [seleccionId];
}
