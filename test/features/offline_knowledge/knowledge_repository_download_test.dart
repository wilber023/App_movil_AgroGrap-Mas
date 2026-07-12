import 'package:flutter_test/flutter_test.dart';

import 'package:agrograp_movil/features/offline_knowledge/data/datasources/knowledge_local_datasource.dart';
import 'package:agrograp_movil/features/offline_knowledge/data/datasources/knowledge_remote_datasource.dart';
import 'package:agrograp_movil/features/offline_knowledge/data/models/offline_catalog_document.dart';
import 'package:agrograp_movil/features/offline_knowledge/data/repositories/knowledge_repository_impl.dart';
import 'package:agrograp_movil/features/offline_knowledge/domain/entities/scored_entry.dart';
import 'package:agrograp_movil/features/offline_knowledge/domain/entities/treatment_entry.dart';

/// Fake en memoria de [KnowledgeLocalDataSource] -- registra si
/// `insertPackage` fue invocado y con qué, sin tocar sqflite.
class _FakeLocalDataSource implements KnowledgeLocalDataSource {
  Map<String, dynamic>? lastInserted;

  @override
  Future<void> insertPackage(Map<String, dynamic> json) async {
    lastInserted = json;
  }

  @override
  Future<bool> hasPackage(String cultivo) async => lastInserted != null;

  @override
  Future<TreatmentEntry?> querySQL(String cultivo, String id) async => null;

  @override
  Future<List<ScoredEntry>> vectorSearch({
    required String cultivo,
    required List<double> queryVector,
    required int topK,
  }) async => const [];
}

/// Fake de [KnowledgeRemoteDataSource] -- simula catálogo + descarga de
/// documentos individuales, sin red real.
class _FakeRemoteDataSource implements KnowledgeRemoteDataSource {
  List<OfflineCatalogDocument> catalog = const [];
  Map<String, Map<String, dynamic>> documents = const {};

  /// doc_id que debe fallar al descargarse (simula el N-ésimo documento
  /// fallando a mitad de la descarga de un cultivo).
  String? failingDocId;

  @override
  Future<List<OfflineCatalogDocument>> getCatalog() async => catalog;

  @override
  Future<Map<String, dynamic>> downloadDocument(String docId) async {
    if (docId == failingDocId) {
      throw Exception('fallo simulado descargando $docId');
    }
    return documents[docId]!;
  }
}

void main() {
  late _FakeLocalDataSource local;
  late _FakeRemoteDataSource remote;
  late KnowledgeRepositoryImpl repository;

  setUp(() {
    local = _FakeLocalDataSource();
    remote = _FakeRemoteDataSource();
    repository = KnowledgeRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
    );
  });

  const doc1 = OfflineCatalogDocument(
    id: 'doc_a1',
    cropName: 'maiz',
    diseaseName: 'roya comun',
    title: 'Maiz — roya',
    source: 'CIMMYT',
    sizeBytes: 100,
    version: '1.0',
  );
  const doc2 = OfflineCatalogDocument(
    id: 'doc_a2',
    cropName: 'maiz',
    diseaseName: 'mancha foliar',
    title: 'Maiz — mancha',
    source: 'INIFAP',
    sizeBytes: 120,
    version: '1.0',
  );

  test(
    'catálogo con 2 documentos del cultivo -> arma 2 fichas e instala el paquete',
    () async {
      remote.catalog = [doc1, doc2];
      remote.documents = {
        'doc_a1': {'id': 'doc_a1', 'content': 'tratamiento roya...', 'embedding': [0.1]},
        'doc_a2': {'id': 'doc_a2', 'content': 'tratamiento mancha...', 'embedding': [0.2]},
      };

      await repository.downloadAndInstallPackage('maiz');

      expect(local.lastInserted, isNotNull);
      final fichas = local.lastInserted!['fichas'] as List;
      expect(fichas, hasLength(2));
      expect(fichas[0]['id'], 'roya comun');
      expect(fichas[0]['tratamiento'], 'tratamiento roya...');
      expect(await repository.hasPackageFor('maiz'), isTrue);
    },
  );

  test(
    'cultivo sin documentos en el catálogo -> ValidationException, no instala nada',
    () async {
      remote.catalog = [doc1]; // ninguno es de "frijol"

      await expectLater(
        () => repository.downloadAndInstallPackage('frijol'),
        throwsA(isA<Exception>()),
      );

      expect(local.lastInserted, isNull);
    },
  );

  test(
    'uno de N documentos falla a mitad de la descarga -> se descarta todo el '
    'lote, no se instala nada (se conserva lo que ya hubiera antes)',
    () async {
      remote.catalog = [doc1, doc2];
      remote.documents = {
        'doc_a1': {'id': 'doc_a1', 'content': 'tratamiento roya...', 'embedding': [0.1]},
      };
      remote.failingDocId = 'doc_a2'; // el segundo documento falla

      await expectLater(
        () => repository.downloadAndInstallPackage('maiz'),
        throwsA(isA<Exception>()),
      );

      // No se instaló nada -- ni siquiera el primer documento que sí bajó bien.
      expect(local.lastInserted, isNull);
      expect(await repository.hasPackageFor('maiz'), isFalse);
    },
  );
}
