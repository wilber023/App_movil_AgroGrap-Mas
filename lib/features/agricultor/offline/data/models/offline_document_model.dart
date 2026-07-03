import '../../domain/entities/offline_document_entity.dart';

class OfflineDocumentModel extends OfflineDocumentEntity {
  const OfflineDocumentModel({
    required super.id,
    required super.cropName,
    required super.diseaseName,
    required super.title,
    required super.content,
    required super.source,
    required super.sizeBytes,
    required super.status,
    super.downloadedAt,
    super.version,
    required super.createdAt,
  });

  factory OfflineDocumentModel.fromRow(Map<String, dynamic> row) {
    return OfflineDocumentModel(
      id: row['id'] as String,
      cropName: row['crop_name'] as String,
      diseaseName: row['disease_name'] as String,
      title: row['title'] as String,
      content: row['content'] as String,
      source: row['source'] as String,
      sizeBytes: row['size_bytes'] as int? ?? 0,
      status: _statusFromString(row['status'] as String? ?? 'available'),
      downloadedAt: row['downloaded_at'] != null
          ? DateTime.tryParse(row['downloaded_at'] as String)
          : null,
      version: row['version'] as String? ?? '1.0',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'crop_name': cropName,
        'disease_name': diseaseName,
        'title': title,
        'content': content,
        'source': source,
        'size_bytes': sizeBytes,
        'status': _statusToString(status),
        'downloaded_at': downloadedAt?.toIso8601String(),
        'version': version,
        'created_at': createdAt.toIso8601String(),
      };

  static OfflineDocumentStatus _statusFromString(String s) {
    return switch (s) {
      'downloading' => OfflineDocumentStatus.downloading,
      'downloaded' => OfflineDocumentStatus.downloaded,
      'error' => OfflineDocumentStatus.error,
      _ => OfflineDocumentStatus.available,
    };
  }

  static String _statusToString(OfflineDocumentStatus s) {
    return switch (s) {
      OfflineDocumentStatus.downloading => 'downloading',
      OfflineDocumentStatus.downloaded => 'downloaded',
      OfflineDocumentStatus.error => 'error',
      OfflineDocumentStatus.available => 'available',
    };
  }
}
