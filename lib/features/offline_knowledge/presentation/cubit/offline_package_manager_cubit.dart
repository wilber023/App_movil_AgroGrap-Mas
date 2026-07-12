// =============================================================================
// AgroGraph-MAS — OfflinePackageManagerCubit
// Estado de descarga por cultivo para Perfil → "Diagnóstico sin Conexión".
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../domain/cultivo_slug.dart';
import '../../domain/repositories/knowledge_repository.dart';

enum PackageDownloadPhase { notDownloaded, downloading, downloaded, error }

class CropPackageStatus extends Equatable {
  /// Nombre de cultivo tal como se muestra en la UI (ej. "Maíz").
  final String cultivo;

  /// Slug enviado al backend / usado como clave local (ej. "maiz").
  final String slug;

  final PackageDownloadPhase phase;
  final String? errorMessage;

  const CropPackageStatus({
    required this.cultivo,
    required this.slug,
    required this.phase,
    this.errorMessage,
  });

  CropPackageStatus copyWith({
    PackageDownloadPhase? phase,
    String? errorMessage,
  }) => CropPackageStatus(
    cultivo: cultivo,
    slug: slug,
    phase: phase ?? this.phase,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [cultivo, slug, phase, errorMessage];
}

class OfflinePackageManagerState extends Equatable {
  final bool loading;
  final Map<String, CropPackageStatus> statuses;

  const OfflinePackageManagerState({
    this.loading = false,
    this.statuses = const {},
  });

  OfflinePackageManagerState copyWith({
    bool? loading,
    Map<String, CropPackageStatus>? statuses,
  }) => OfflinePackageManagerState(
    loading: loading ?? this.loading,
    statuses: statuses ?? this.statuses,
  );

  @override
  List<Object?> get props => [loading, statuses];
}

class OfflinePackageManagerCubit extends Cubit<OfflinePackageManagerState> {
  final KnowledgeRepository _repository;

  /// Cultivos soportados hoy — mismo set que ya usaba la UI de "Diagnóstico
  /// sin Conexión" (offline_mode_page.dart). No existe un endpoint de
  /// catálogo para offline_knowledge (fuera de alcance, ver sección 1 y 11
  /// del documento de especificación), así que la lista es estática hasta
  /// que exista uno.
  static const List<String> supportedCrops = [
    'Tomate',
    'Maíz',
    'Papa',
    'Frijol',
    'Calabaza',
  ];

  OfflinePackageManagerCubit(this._repository)
    : super(const OfflinePackageManagerState());

  /// Consulta `hasPackageFor` para cada cultivo soportado y arma el estado
  /// inicial de la pantalla.
  Future<void> loadStatuses() async {
    emit(state.copyWith(loading: true));
    final statuses = <String, CropPackageStatus>{};
    for (final crop in supportedCrops) {
      final slug = cultivoSlug(crop);
      final downloaded = await _repository.hasPackageFor(slug);
      statuses[crop] = CropPackageStatus(
        cultivo: crop,
        slug: slug,
        phase: downloaded
            ? PackageDownloadPhase.downloaded
            : PackageDownloadPhase.notDownloaded,
      );
    }
    emit(state.copyWith(loading: false, statuses: statuses));
  }

  /// Descarga e instala el paquete de [cropNameEs] llamando directamente a
  /// `KnowledgeRepository.downloadAndInstallPackage` — no reimplementa la
  /// descarga ni la validación del paquete, solo refleja su resultado.
  Future<void> download(String cropNameEs) async {
    _update(cropNameEs, (s) => s.copyWith(
      phase: PackageDownloadPhase.downloading,
      errorMessage: null,
    ));
    try {
      final slug = cultivoSlug(cropNameEs);
      await _repository.downloadAndInstallPackage(slug);
      _update(
        cropNameEs,
        (s) => s.copyWith(phase: PackageDownloadPhase.downloaded),
      );
    } catch (e) {
      _update(
        cropNameEs,
        (s) => s.copyWith(
          phase: PackageDownloadPhase.error,
          errorMessage: _friendlyMessage(e),
        ),
      );
    }
  }

  void _update(
    String cultivo,
    CropPackageStatus Function(CropPackageStatus current) update,
  ) {
    final current = state.statuses[cultivo];
    if (current == null) return;
    final next = Map<String, CropPackageStatus>.from(state.statuses);
    next[cultivo] = update(current);
    emit(state.copyWith(statuses: next));
  }

  /// Mapea las excepciones tipadas de `core/network/api_exceptions.dart`
  /// (lanzadas por `ApiClient` vía `KnowledgeRemoteDataSource`) a un mensaje
  /// legible, sin exponer detalle crudo del backend.
  String _friendlyMessage(Object e) {
    if (e is ServerException) {
      return 'Error en el servidor. Intenta más tarde.';
    }
    if (e is ValidationException) {
      return 'El paquete recibido no es válido. Intenta más tarde.';
    }
    if (e is UnauthorizedException) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión.';
    }
    if (e is NetworkException) {
      if (e.statusCode == 404) {
        return 'Este cultivo aún no tiene paquete disponible en el servidor.';
      }
      return 'Sin conexión. Verifica tu red e intenta de nuevo.';
    }
    return 'No se pudo descargar el paquete. Intenta de nuevo.';
  }
}
