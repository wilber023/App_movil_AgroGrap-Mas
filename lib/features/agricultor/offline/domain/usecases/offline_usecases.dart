import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/offline_document_entity.dart';
import '../entities/offline_status_entity.dart';
import '../repositories/offline_repository.dart';

class GetOfflineStatusUseCase
    implements UseCase<OfflineStatusEntity, NoParams> {
  final OfflineRepository _repo;
  const GetOfflineStatusUseCase(this._repo);

  @override
  Future<Either<Failure, OfflineStatusEntity>> call(NoParams params) =>
      _repo.getStatus();
}

class ToggleOfflineModeUseCase implements UseCase<void, bool> {
  final OfflineRepository _repo;
  const ToggleOfflineModeUseCase(this._repo);

  @override
  Future<Either<Failure, void>> call(bool params) =>
      _repo.toggleOfflineMode(enabled: params);
}

class GetOfflineCatalogUseCase
    implements UseCase<List<OfflineDocumentEntity>, NoParams> {
  final OfflineRepository _repo;
  const GetOfflineCatalogUseCase(this._repo);

  @override
  Future<Either<Failure, List<OfflineDocumentEntity>>> call(NoParams params) =>
      _repo.getCatalog();
}

class DownloadOfflineDocumentUseCase implements UseCase<void, String> {
  final OfflineRepository _repo;
  const DownloadOfflineDocumentUseCase(this._repo);

  @override
  Future<Either<Failure, void>> call(String params) =>
      _repo.downloadDocument(params);
}

class DeleteOfflineDocumentUseCase implements UseCase<void, String> {
  final OfflineRepository _repo;
  const DeleteOfflineDocumentUseCase(this._repo);

  @override
  Future<Either<Failure, void>> call(String params) =>
      _repo.deleteDocument(params);
}
