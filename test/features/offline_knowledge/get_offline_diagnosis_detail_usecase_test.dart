import 'package:flutter_test/flutter_test.dart';

import 'package:agrograp_movil/features/offline_knowledge/data/datasources/embedding_model_datasource.dart';
import 'package:agrograp_movil/features/offline_knowledge/domain/entities/diagnosis_detail.dart';
import 'package:agrograp_movil/features/offline_knowledge/domain/entities/scored_entry.dart';
import 'package:agrograp_movil/features/offline_knowledge/domain/entities/treatment_entry.dart';
import 'package:agrograp_movil/features/offline_knowledge/domain/repositories/knowledge_repository.dart';
import 'package:agrograp_movil/features/offline_knowledge/domain/usecases/get_offline_diagnosis_detail_usecase.dart';

/// Fake en memoria de [KnowledgeRepository] — sin sqflite, solo para tests.
class _FakeKnowledgeRepository implements KnowledgeRepository {
  bool hasPackage = true;
  TreatmentEntry? exactMatch;
  List<ScoredEntry> similarityResults = const [];

  @override
  Future<bool> hasPackageFor(String cultivo) async => hasPackage;

  @override
  Future<TreatmentEntry?> getByExactId(String cultivo, String id) async =>
      exactMatch;

  @override
  Future<List<ScoredEntry>> searchBySimilarity({
    required String cultivo,
    required List<double> queryVector,
    required int topK,
  }) async => similarityResults;

  @override
  Future<void> insertPackage(Map<String, dynamic> json) async {}

  @override
  Future<void> downloadAndInstallPackage(String cultivo) async {}
}

/// Fake determinístico de [EmbeddingModelDataSource] — no requiere TFLite.
class _FakeEmbeddingModelDataSource implements EmbeddingModelDataSource {
  @override
  Future<List<double>> encode(String text) async => [1.0, 0.0, 0.0];
}

void main() {
  late _FakeKnowledgeRepository repository;
  late _FakeEmbeddingModelDataSource embeddingModel;
  late GetOfflineDiagnosisDetailUseCase useCase;

  const cultivo = 'maiz';
  const enfermedadId = 'roya_comun';

  final ficha = TreatmentEntry(
    id: enfermedadId,
    cultivo: cultivo,
    enfermedad: 'Roya común',
    sintomas: 'Pústulas anaranjadas en el envés de las hojas.',
    tratamiento: 'Aplicar fungicida triazol cada 10-14 días.',
    severidad: 'media',
    embedding: const [1.0, 0.0, 0.0],
  );

  setUp(() {
    repository = _FakeKnowledgeRepository();
    embeddingModel = _FakeEmbeddingModelDataSource();
    useCase = GetOfflineDiagnosisDetailUseCase(repository, embeddingModel);
  });

  test('paquete no descargado -> packageMissing', () async {
    repository.hasPackage = false;

    final result = await useCase(
      cultivo: cultivo,
      enfermedadId: enfermedadId,
      confianzaCnn: 0.9,
    );

    expect(result, isA<DiagnosisDetailPackageMissing>());
    expect((result as DiagnosisDetailPackageMissing).cultivo, cultivo);
    expect(result.source, DiagnosisSource.packageMissing);
  });

  test('match exacto por ID -> exact', () async {
    repository.exactMatch = ficha;

    final result = await useCase(
      cultivo: cultivo,
      enfermedadId: enfermedadId,
      confianzaCnn: 0.91,
    );

    expect(result, isA<DiagnosisDetailExact>());
    final exact = result as DiagnosisDetailExact;
    expect(exact.ficha, ficha);
    expect(exact.confianzaCnn, 0.91);
    expect(result.enfermedad, 'Roya común');
    expect(result.source, DiagnosisSource.exactMatch);
  });

  test(
    'sin match exacto, fallback semántico exitoso (score >= umbral) -> approximate',
    () async {
      repository.exactMatch = null;
      repository.similarityResults = [ScoredEntry(ficha: ficha, score: 0.71)];

      final result = await useCase(
        cultivo: cultivo,
        enfermedadId: 'clase_nueva_no_en_paquete',
        confianzaCnn: 0.85,
      );

      expect(result, isA<DiagnosisDetailApproximate>());
      final approx = result as DiagnosisDetailApproximate;
      expect(approx.ficha, ficha);
      expect(approx.score, 0.71);
      expect(result.source, DiagnosisSource.semanticFallback);
    },
  );

  test(
    'sin match exacto, fallback semántico por debajo del umbral -> notFound',
    () async {
      repository.exactMatch = null;
      repository.similarityResults = [ScoredEntry(ficha: ficha, score: 0.40)];

      final result = await useCase(
        cultivo: cultivo,
        enfermedadId: 'clase_desconocida',
        confianzaCnn: 0.85,
      );

      expect(result, isA<DiagnosisDetailNotFound>());
      expect(
        (result as DiagnosisDetailNotFound).enfermedadId,
        'clase_desconocida',
      );
      expect(result.source, DiagnosisSource.notFound);
    },
  );

  test('sin resultados de similitud -> notFound', () async {
    repository.exactMatch = null;
    repository.similarityResults = const [];

    final result = await useCase(
      cultivo: cultivo,
      enfermedadId: 'clase_desconocida',
      confianzaCnn: 0.85,
    );

    expect(result, isA<DiagnosisDetailNotFound>());
  });
}
