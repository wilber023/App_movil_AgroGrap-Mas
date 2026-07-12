// =============================================================================
// AgroGraph-MAS — KnowledgeRepository (offline_knowledge)
// Ver agrograph_diagnostico_offline_embeddings.md, sección 4.
// =============================================================================

import '../entities/scored_entry.dart';
import '../entities/treatment_entry.dart';

/// Contrato de acceso al índice local de conocimiento offline.
///
/// [insertPackage] ya queda definida y con implementación funcional en el
/// datasource local para que, cuando el endpoint de descarga esté listo,
/// conectarlo sea solo: llamar al endpoint → parsear JSON → invocar
/// `insertPackage()`. Este feature no realiza esa llamada de red.
abstract interface class KnowledgeRepository {
  /// Busca una ficha por ID exacto dentro del paquete de un cultivo.
  Future<TreatmentEntry?> getByExactId(String cultivo, String id);

  /// Busca las [topK] fichas más similares a [queryVector] dentro del
  /// paquete de un cultivo, ordenadas por score de similitud coseno
  /// descendente.
  Future<List<ScoredEntry>> searchBySimilarity({
    required String cultivo,
    required List<double> queryVector,
    required int topK,
  });

  /// Indica si existe un paquete de conocimiento descargado para [cultivo].
  Future<bool> hasPackageFor(String cultivo);

  /// Indexa un paquete de conocimiento ya descargado y parseado a JSON.
  ///
  /// Reemplaza por completo el índice previo de ese cultivo (no se mezclan
  /// versiones distintas del `embedding_model`, ver sección 10).
  Future<void> insertPackage(Map<String, dynamic> json);

  /// Descarga el paquete de [cultivo] desde el backend y lo indexa.
  ///
  /// Internamente: `KnowledgeRemoteDataSource.downloadPackage` →
  /// `insertPackage`. Si la descarga falla o el JSON viene corrupto/vacío,
  /// no se toca el índice local existente de ese cultivo (o se instala
  /// completo, o no se instala nada).
  Future<void> downloadAndInstallPackage(String cultivo);
}
