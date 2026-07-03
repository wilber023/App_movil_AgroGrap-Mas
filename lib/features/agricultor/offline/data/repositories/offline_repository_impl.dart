import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../domain/entities/offline_document_entity.dart';
import '../../domain/entities/offline_status_entity.dart';
import '../../domain/repositories/offline_repository.dart';
import '../datasources/offline_local_datasource.dart';

class OfflineRepositoryImpl implements OfflineRepository {
  final OfflineLocalDataSource _dataSource;

  const OfflineRepositoryImpl({required OfflineLocalDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Either<Failure, OfflineStatusEntity>> getStatus() async {
    try {
      final enabled = await _dataSource.getOfflineModeEnabled();
      final lastSync = await _dataSource.getLastSyncAt();
      final catalog = await _dataSource.getCatalog();
      final usedBytes = await _dataSource.getTotalUsedBytes();

      final downloaded = catalog
          .where((d) => d.status == OfflineDocumentStatus.downloaded)
          .length;

      return Right(OfflineStatusEntity(
        isOfflineModeEnabled: enabled,
        downloadedCount: downloaded,
        totalAvailableCount: catalog.length,
        usedBytes: usedBytes,
        lastSyncAt: lastSync,
      ));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleOfflineMode(
      {required bool enabled}) async {
    try {
      await _dataSource.setOfflineModeEnabled(enabled);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OfflineDocumentEntity>>> getCatalog() async {
    try {
      final docs = await _dataSource.getCatalog();
      return Right(docs);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> downloadDocument(String documentId) async {
    try {
      // Marcamos como "descargando"
      await _dataSource.setDocumentStatus(documentId, 'downloading');

      // PUNTO DE INTEGRACIÓN LLM/RAG:
      // Aquí el equipo LLM debe:
      //   1. GET /api/v1/offline/documents/{documentId}
      //   2. Recibir: {content, embedding_json, size_bytes}
      //   3. Guardar en local_indexes chunks + embeddings
      //   4. Actualizar size_bytes real
      //
      // Por ahora simulamos la descarga con delay de 1.5s.
      await Future.delayed(const Duration(milliseconds: 1500));

      await _dataSource.setDocumentStatus(
        documentId,
        'downloaded',
        downloadedAt: DateTime.now(),
      );
      await _dataSource.setLastSyncAt(DateTime.now());
      return const Right(null);
    } catch (e) {
      await _dataSource.setDocumentStatus(documentId, 'error');
      return Left(CacheFailure(message: 'Error al descargar: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDocument(String documentId) async {
    try {
      await _dataSource.deleteDocument(documentId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
