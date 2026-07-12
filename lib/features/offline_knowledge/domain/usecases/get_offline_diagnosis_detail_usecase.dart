// =============================================================================
// AgroGraph-MAS — GetOfflineDiagnosisDetailUseCase (offline_knowledge)
// Orquesta match exacto → fallback semántico → not found.
// Ver agrograph_diagnostico_offline_embeddings.md, sección 6.
// =============================================================================

import '../../data/datasources/embedding_model_datasource.dart';
import '../entities/diagnosis_detail.dart';
import '../repositories/knowledge_repository.dart';

class GetOfflineDiagnosisDetailUseCase {
  final KnowledgeRepository repository;
  final EmbeddingModelDataSource embeddingModel;

  /// Umbral mínimo de similitud coseno para aceptar un fallback semántico
  /// como resultado usable (sección 6 y 11 — valor de arranque, no validado
  /// con datos reales; único lugar a ajustar cuando se calibre).
  static const double similarityThreshold = 0.55;

  GetOfflineDiagnosisDetailUseCase(this.repository, this.embeddingModel);

  Future<DiagnosisDetail> call({
    required String cultivo,
    required String enfermedadId, // viene directo de la CNN
    required double confianzaCnn,
  }) async {
    final tienePaquete = await repository.hasPackageFor(cultivo);
    if (!tienePaquete) {
      return DiagnosisDetail.packageMissing(cultivo);
    }

    // Intento 1: ID exacto (nombre español del CNN, ya lowercased)
    var ficha = await repository.getByExactId(cultivo, enfermedadId);

    // Intento 2: sin acentos — cubre el caso en que el backend almacene
    // "tizon tardio" en lugar de "tizón tardío"
    if (ficha == null) {
      final stripped = _stripAccents(enfermedadId);
      if (stripped != enfermedadId) {
        ficha = await repository.getByExactId(cultivo, stripped);
      }
    }

    if (ficha != null) return DiagnosisDetail.exact(ficha, confianzaCnn);

    // No está en el paquete local → fallback semántico
    return _fallbackSemantico(cultivo, enfermedadId);
  }

  /// Elimina tildes y ñ para comparación tolerante con distintas normalizaciones
  /// del backend ("tizon tardio" vs "tizón tardío").
  static String _stripAccents(String s) => s
      .replaceAll('á', 'a').replaceAll('Á', 'a')
      .replaceAll('é', 'e').replaceAll('É', 'e')
      .replaceAll('í', 'i').replaceAll('Í', 'i')
      .replaceAll('ó', 'o').replaceAll('Ó', 'o')
      .replaceAll('ú', 'u').replaceAll('Ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n').replaceAll('Ñ', 'n');

  Future<DiagnosisDetail> _fallbackSemantico(
    String cultivo,
    String enfermedadId,
  ) async {
    final queryText = _idToSearchableText(enfermedadId, cultivo);
    final queryVector = await embeddingModel.encode(queryText);

    final resultados = await repository.searchBySimilarity(
      cultivo: cultivo,
      queryVector: queryVector,
      topK: 1,
    );

    if (resultados.isEmpty || resultados.first.score < similarityThreshold) {
      return DiagnosisDetail.notFound(enfermedadId);
    }

    return DiagnosisDetail.approximate(
      resultados.first.ficha,
      resultados.first.score,
    );
  }

  String _idToSearchableText(String id, String cultivo) {
    // ej. "roya_comun" + "maiz" → "roya común maíz"
    return '${id.replaceAll('_', ' ')} $cultivo';
  }
}
