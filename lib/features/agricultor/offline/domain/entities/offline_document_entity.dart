import 'package:equatable/equatable.dart';

enum OfflineDocumentStatus { available, downloading, downloaded, error }

class OfflineDocumentEntity extends Equatable {
  final String id;
  final String cropName;
  final String diseaseName;
  final String title;
  final String content;
  final String source;
  final int sizeBytes;
  final OfflineDocumentStatus status;
  final DateTime? downloadedAt;
  final String version;
  final DateTime createdAt;

  const OfflineDocumentEntity({
    required this.id,
    required this.cropName,
    required this.diseaseName,
    required this.title,
    required this.content,
    required this.source,
    required this.sizeBytes,
    required this.status,
    this.downloadedAt,
    this.version = '1.0',
    required this.createdAt,
  });

  bool get isDownloaded => status == OfflineDocumentStatus.downloaded;
  bool get isDownloading => status == OfflineDocumentStatus.downloading;
  bool get isAvailable => status == OfflineDocumentStatus.available;

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  OfflineDocumentEntity copyWith({
    OfflineDocumentStatus? status,
    DateTime? downloadedAt,
    int? sizeBytes,
  }) =>
      OfflineDocumentEntity(
        id: id,
        cropName: cropName,
        diseaseName: diseaseName,
        title: title,
        content: content,
        source: source,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        status: status ?? this.status,
        downloadedAt: downloadedAt ?? this.downloadedAt,
        version: version,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, status, sizeBytes, downloadedAt];
}
