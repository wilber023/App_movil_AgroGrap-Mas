import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/offline_document_entity.dart';
import '../../domain/entities/offline_status_entity.dart';
import '../../domain/usecases/offline_usecases.dart';

// =============================================================================
// STATES
// =============================================================================

sealed class OfflineState extends Equatable {
  const OfflineState();
  @override
  List<Object?> get props => [];
}

final class OfflineInitial extends OfflineState {
  const OfflineInitial();
}

final class OfflineLoading extends OfflineState {
  const OfflineLoading();
}

final class OfflineLoaded extends OfflineState {
  final OfflineStatusEntity status;
  final List<OfflineDocumentEntity> documents;
  final String? downloadingDocId;
  final String? toastError;

  const OfflineLoaded({
    required this.status,
    required this.documents,
    this.downloadingDocId,
    this.toastError,
  });

  bool get isDownloading => downloadingDocId != null;

  OfflineLoaded copyWith({
    OfflineStatusEntity? status,
    List<OfflineDocumentEntity>? documents,
    String? downloadingDocId,
    bool clearDownloading = false,
    String? toastError,
    bool clearToastError = false,
  }) =>
      OfflineLoaded(
        status: status ?? this.status,
        documents: documents ?? this.documents,
        downloadingDocId:
            clearDownloading ? null : downloadingDocId ?? this.downloadingDocId,
        toastError:
            clearToastError ? null : toastError ?? this.toastError,
      );

  @override
  List<Object?> get props => [status, documents, downloadingDocId, toastError];
}

final class OfflineError extends OfflineState {
  final String message;
  const OfflineError({required this.message});
  @override
  List<Object?> get props => [message];
}

// =============================================================================
// CUBIT
// =============================================================================

class OfflineCubit extends Cubit<OfflineState> {
  final GetOfflineStatusUseCase _getStatus;
  final ToggleOfflineModeUseCase _toggleMode;
  final GetOfflineCatalogUseCase _getCatalog;
  final DownloadOfflineDocumentUseCase _download;
  final DeleteOfflineDocumentUseCase _delete;

  OfflineCubit({
    required GetOfflineStatusUseCase getStatusUseCase,
    required ToggleOfflineModeUseCase toggleModeUseCase,
    required GetOfflineCatalogUseCase getCatalogUseCase,
    required DownloadOfflineDocumentUseCase downloadUseCase,
    required DeleteOfflineDocumentUseCase deleteUseCase,
  })  : _getStatus = getStatusUseCase,
        _toggleMode = toggleModeUseCase,
        _getCatalog = getCatalogUseCase,
        _download = downloadUseCase,
        _delete = deleteUseCase,
        super(const OfflineInitial());

  // ---------------------------------------------------------------------------
  // Catálogo estático — disponible sin SQLite.
  // PUNTO DE INTEGRACIÓN: reemplazar por endpoint real cuando esté disponible.
  // ---------------------------------------------------------------------------
  static List<OfflineDocumentEntity> _buildStaticCatalog() {
    final now = DateTime.now();
    return [
      // 🍅 Tomate
      OfflineDocumentEntity(id: 'doc_tomato_lateblight', cropName: 'Tomate', diseaseName: 'Tizón tardío', title: 'Control de Phytophthora infestans en tomate', content: '', source: 'FAO-2023', sizeBytes: 148 * 1024, status: OfflineDocumentStatus.available, version: '2.1', createdAt: now),
      OfflineDocumentEntity(id: 'doc_tomato_earlyblight', cropName: 'Tomate', diseaseName: 'Tizón temprano', title: 'Manejo integrado de Alternaria solani en tomate', content: '', source: 'INIFAP-2022', sizeBytes: 112 * 1024, status: OfflineDocumentStatus.available, version: '1.3', createdAt: now),
      OfflineDocumentEntity(id: 'doc_tomato_mosaic', cropName: 'Tomate', diseaseName: 'Virus del mosaico', title: 'Potato Virus Y en solanáceas', content: '', source: 'INIA-España-2021', sizeBytes: 98 * 1024, status: OfflineDocumentStatus.available, version: '1.0', createdAt: now),
      // 🌽 Maíz
      OfflineDocumentEntity(id: 'doc_corn_rust', cropName: 'Maíz', diseaseName: 'Roya común', title: 'Protocolo fitosanitario para Puccinia sorghi', content: '', source: 'CIMMYT-2022', sizeBytes: 134 * 1024, status: OfflineDocumentStatus.available, version: '1.5', createdAt: now),
      OfflineDocumentEntity(id: 'doc_corn_leafspot', cropName: 'Maíz', diseaseName: 'Mancha foliar gris', title: 'Cercospora zeae-maydis: manejo en campo', content: '', source: 'INIFAP-2023', sizeBytes: 89 * 1024, status: OfflineDocumentStatus.available, version: '1.1', createdAt: now),
      // 🥔 Papa
      OfflineDocumentEntity(id: 'doc_potato_lateblight', cropName: 'Papa', diseaseName: 'Tizón tardío', title: 'Guía de control de Phytophthora infestans en papa', content: '', source: 'CIP-Lima-2023', sizeBytes: 165 * 1024, status: OfflineDocumentStatus.available, version: '3.0', createdAt: now),
      // 🫘 Frijol
      OfflineDocumentEntity(id: 'doc_bean_anthracnose', cropName: 'Frijol', diseaseName: 'Antracnosis', title: 'Colletotrichum lindemuthianum en frijol', content: '', source: 'CIAT-2022', sizeBytes: 107 * 1024, status: OfflineDocumentStatus.available, version: '1.2', createdAt: now),
      // 🎃 Calabaza
      OfflineDocumentEntity(id: 'doc_squash_powdery', cropName: 'Calabaza', diseaseName: 'Mildiú polvoroso', title: 'Podosphaera xanthii en cucurbitáceas: manejo integrado', content: '', source: 'FAO-2022', sizeBytes: 103 * 1024, status: OfflineDocumentStatus.available, version: '1.1', createdAt: now),
    ];
  }

  // ---------------------------------------------------------------------------
  // loadStatus — NUNCA emite OfflineError.
  // Si SQLite falla usa el catálogo estático como fallback.
  // ---------------------------------------------------------------------------
  Future<void> loadStatus() async {
    if (state is! OfflineLoaded) emit(const OfflineLoading());

    final statusResult = await _getStatus(const NoParams());
    final catalogResult = await _getCatalog(const NoParams());

    final status = statusResult.fold(
      (_) => const OfflineStatusEntity(
        isOfflineModeEnabled: false,
        downloadedCount: 0,
        totalAvailableCount: 0,
        usedBytes: 0,
      ),
      (s) => s,
    );

    final docs = catalogResult.fold(
      (_) => _buildStaticCatalog(),
      (d) => d.isNotEmpty ? d : _buildStaticCatalog(),
    );

    if (!isClosed) {
      emit(OfflineLoaded(
        status: status.copyWith(totalAvailableCount: docs.length),
        documents: docs,
      ));
    }
  }

  /// Limpia el toastError del estado después de que la UI lo consumió.
  void clearToastError() {
    final current = state;
    if (current is OfflineLoaded && current.toastError != null) {
      emit(current.copyWith(clearToastError: true));
    }
  }

  Future<void> toggleOfflineMode({required bool enabled}) async {
    final current = state;
    if (current is! OfflineLoaded) return;

    // Actualización optimista — funciona en sesión aunque SQLite falle
    emit(current.copyWith(
      status: current.status.copyWith(isOfflineModeEnabled: enabled),
    ));

    // Persiste en background; error se ignora silenciosamente (persistencia opcional)
    await _toggleMode(enabled);
  }

  Future<void> downloadDocument(String documentId) async {
    final current = state;
    if (current is! OfflineLoaded) return;
    if (current.isDownloading) return;

    final updatedDocs = current.documents.map((d) => d.id == documentId
        ? d.copyWith(status: OfflineDocumentStatus.downloading)
        : d).toList();
    emit(current.copyWith(documents: updatedDocs, downloadingDocId: documentId));

    final result = await _download(documentId);
    result.fold(
      (f) {
        final curr = state;
        if (curr is! OfflineLoaded) return;
        final resetDocs = curr.documents.map((d) => d.id == documentId
            ? d.copyWith(status: OfflineDocumentStatus.available)
            : d).toList();
        emit(curr.copyWith(
          documents: resetDocs,
          clearDownloading: true,
          toastError: 'Descarga no disponible aún. El servicio de guías offline se integrará próximamente.',
        ));
      },
      (_) => loadStatus(),
    );
  }

  /// Descarga todos los docs de un cultivo de forma secuencial.
  /// Si falla, emite toastError y detiene la cola.
  Future<void> downloadCropDocs(List<String> documentIds) async {
    for (final docId in documentIds) {
      if (isClosed) return;
      final current = state;
      if (current is! OfflineLoaded) return;

      final idx = current.documents.indexWhere((d) => d.id == docId);
      if (idx < 0 || current.documents[idx].isDownloaded) continue;

      final updatedDocs = List.of(current.documents);
      updatedDocs[idx] =
          updatedDocs[idx].copyWith(status: OfflineDocumentStatus.downloading);
      emit(current.copyWith(documents: updatedDocs, downloadingDocId: docId));

      final result = await _download(docId);
      if (isClosed) return;

      final afterState = state;
      if (afterState is! OfflineLoaded) return;

      bool hadError = false;
      result.fold(
        (f) {
          hadError = true;
          final afterDocs = List.of(afterState.documents);
          final afterIdx = afterDocs.indexWhere((d) => d.id == docId);
          if (afterIdx >= 0) {
            afterDocs[afterIdx] = afterDocs[afterIdx]
                .copyWith(status: OfflineDocumentStatus.available);
          }
          emit(afterState.copyWith(
            documents: afterDocs,
            clearDownloading: true,
            toastError:
                'Descarga no disponible. El backend de guías offline se integrará próximamente.',
          ));
        },
        (_) {
          final afterDocs = List.of(afterState.documents);
          final afterIdx = afterDocs.indexWhere((d) => d.id == docId);
          if (afterIdx >= 0) {
            afterDocs[afterIdx] = afterDocs[afterIdx].copyWith(
              status: OfflineDocumentStatus.downloaded,
              downloadedAt: DateTime.now(),
            );
          }
          emit(afterState.copyWith(documents: afterDocs, clearDownloading: true));
        },
      );

      if (hadError) break;
    }

    if (!isClosed) await loadStatus();
  }

  Future<void> deleteDocument(String documentId) async {
    final current = state;
    if (current is! OfflineLoaded) return;

    final result = await _delete(documentId);
    result.fold(
      (f) {
        final curr = state;
        if (curr is OfflineLoaded) {
          emit(curr.copyWith(
            toastError: 'No se pudo eliminar. Intenta de nuevo.',
          ));
        }
      },
      (_) => loadStatus(),
    );
  }

  /// Elimina todos los docs de un cultivo y recarga una sola vez.
  Future<void> deleteCropDocs(List<String> documentIds) async {
    for (final docId in documentIds) {
      if (isClosed) return;
      await _delete(docId);
    }
    if (!isClosed) await loadStatus();
  }
}
