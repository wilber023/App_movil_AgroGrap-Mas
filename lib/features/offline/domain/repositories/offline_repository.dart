import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/offline_document_entity.dart';
import '../entities/offline_status_entity.dart';

/// Contrato del repositorio offline.
///
/// PUNTO DE INTEGRACIÓN para el equipo LLM/RAG:
/// - [getCatalog] devolverá los documentos disponibles en el backend RAG.
/// - [downloadDocument] descargará el contenido real + embeddings del documento.
/// - Los embeddings almacenados localmente alimentarán el retrieval offline.
abstract interface class OfflineRepository {
  Future<Either<Failure, OfflineStatusEntity>> getStatus();
  Future<Either<Failure, void>> toggleOfflineMode({required bool enabled});
  Future<Either<Failure, List<OfflineDocumentEntity>>> getCatalog();
  Future<Either<Failure, void>> downloadDocument(String documentId);
  Future<Either<Failure, void>> deleteDocument(String documentId);
}
