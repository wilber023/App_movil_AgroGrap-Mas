// =============================================================================
// AgroGraph-MAS — OfflineCatalogDocument (offline_knowledge)
// Entrada de GET /api/v1/offline/catalog (ver README_ofline.md, sección 7).
// Un documento por cada par (cultivo, fuente) del corpus -- no es un
// paquete por cultivo, un cultivo puede tener varios documentos.
// =============================================================================

class OfflineCatalogDocument {
  final String id;
  final String cropName;
  final String diseaseName;
  final String title;
  final String source;
  final int sizeBytes;
  final String version;

  const OfflineCatalogDocument({
    required this.id,
    required this.cropName,
    required this.diseaseName,
    required this.title,
    required this.source,
    required this.sizeBytes,
    required this.version,
  });

  factory OfflineCatalogDocument.fromJson(Map<String, dynamic> json) =>
      OfflineCatalogDocument(
        id: json['id'] as String,
        cropName: json['crop_name'] as String,
        diseaseName: json['disease_name'] as String,
        title: json['title'] as String? ?? '',
        source: json['source'] as String? ?? '',
        sizeBytes: json['size_bytes'] as int? ?? 0,
        version: json['version'] as String? ?? '',
      );
}
