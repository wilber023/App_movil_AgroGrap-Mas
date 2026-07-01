import 'package:equatable/equatable.dart';

class OfflineStatusEntity extends Equatable {
  final bool isOfflineModeEnabled;
  final int downloadedCount;
  final int totalAvailableCount;
  final int usedBytes;
  final DateTime? lastSyncAt;

  const OfflineStatusEntity({
    required this.isOfflineModeEnabled,
    required this.downloadedCount,
    required this.totalAvailableCount,
    required this.usedBytes,
    this.lastSyncAt,
  });

  String get usedBytesLabel {
    if (usedBytes < 1024) return '$usedBytes B';
    if (usedBytes < 1024 * 1024) {
      return '${(usedBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(usedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  OfflineStatusEntity copyWith({
    bool? isOfflineModeEnabled,
    int? downloadedCount,
    int? totalAvailableCount,
    int? usedBytes,
    DateTime? lastSyncAt,
  }) =>
      OfflineStatusEntity(
        isOfflineModeEnabled:
            isOfflineModeEnabled ?? this.isOfflineModeEnabled,
        downloadedCount: downloadedCount ?? this.downloadedCount,
        totalAvailableCount: totalAvailableCount ?? this.totalAvailableCount,
        usedBytes: usedBytes ?? this.usedBytes,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      );

  @override
  List<Object?> get props =>
      [isOfflineModeEnabled, downloadedCount, usedBytes, lastSyncAt];
}
