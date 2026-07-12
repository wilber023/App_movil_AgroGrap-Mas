// =============================================================================
// AgroGraph-MAS — KnowledgeRepositoryImpl (offline_knowledge)
// =============================================================================

import '../../../../core/network/api_exceptions.dart';
import '../../domain/entities/scored_entry.dart';
import '../../domain/entities/treatment_entry.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../datasources/knowledge_local_datasource.dart';
import '../datasources/knowledge_remote_datasource.dart';

class KnowledgeRepositoryImpl implements KnowledgeRepository {
  final KnowledgeLocalDataSource localDataSource;
  final KnowledgeRemoteDataSource remoteDataSource;

  KnowledgeRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<TreatmentEntry?> getByExactId(String cultivo, String id) =>
      localDataSource.querySQL(cultivo, id);

  @override
  Future<List<ScoredEntry>> searchBySimilarity({
    required String cultivo,
    required List<double> queryVector,
    required int topK,
  }) => localDataSource.vectorSearch(
    cultivo: cultivo,
    queryVector: queryVector,
    topK: topK,
  );

  @override
  Future<bool> hasPackageFor(String cultivo) =>
      localDataSource.hasPackage(cultivo);

  @override
  Future<void> insertPackage(Map<String, dynamic> json) =>
      localDataSource.insertPackage(json);

  @override
  Future<void> downloadAndInstallPackage(String cultivo) async {
    // Contrato real (README_ofline.md, secciones 7-8): no existe "un
    // paquete por cultivo" en el backend. Se arma aquí, en memoria:
    //   1. GET /offline/catalog (todos los cultivos)
    //   2. Filtrar los documentos de `cultivo`
    //   3. GET /offline/documents/{doc_id} para cada uno
    //   4. Ensamblar el JSON que insertPackage() ya espera
    //
    // Si CUALQUIER documento falla, se descarta todo este intento (no se
    // llama a insertPackage en absoluto) y lo que ya hubiera instalado una
    // descarga anterior exitosa queda intacto -- insertPackage() no se
    // toca, sigue siendo "todo o nada" por cultivo.
    final catalog = await remoteDataSource.getCatalog();
    final matching = catalog
        .where((doc) => doc.cropName.toLowerCase() == cultivo.toLowerCase())
        .toList();

    if (matching.isEmpty) {
      throw ValidationException(
        message: 'No hay documentos disponibles para "$cultivo" en el catálogo.',
      );
    }

    final fichas = <Map<String, dynamic>>[];
    for (final doc in matching) {
      final docJson = await remoteDataSource.downloadDocument(doc.id);
      fichas.add({
        'id': doc.diseaseName.toLowerCase(),
        'enfermedad': doc.diseaseName,
        'sintomas': '',
        'tratamiento': docJson['content'] as String? ?? '',
        'severidad': '',
        'embedding': docJson['embedding'] ?? const [],
      });
    }

    final packageJson = {
      'cultivo': cultivo.toLowerCase(),
      'version': matching.first.version,
      'embedding_model': 'paraphrase-multilingual-MiniLM-L12-v2',
      'embedding_dim': 384,
      'fichas': fichas,
    };

    // insertPackage ya valida `fichas.isNotEmpty` y reemplaza el índice
    // previo dentro de una única transacción: si algo falla aquí, sqflite
    // revierte todo y el índice existente de `cultivo` queda intacto.
    await localDataSource.insertPackage(packageJson);
  }
}
