import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../models/aprendiz_progress_model.dart';

/// Fuente remota del progreso/gamificacion del Perfil Aprendiz.
///
/// El endpoint aun no esta expuesto por el backend (ver
/// [ApiEndpoints.profile.progress] / TODO en ese archivo). El metodo ya
/// esta implementado contra [ApiClient] siguiendo el mismo patron que el
/// resto de la app: cuando el backend publique la URL real, esta clase no
/// necesita cambios adicionales. Mientras tanto, [AprendizProfileRepositoryImpl]
/// cae siempre al calculo local (ver ese archivo).
abstract class AprendizProfileRemoteDataSource {
  Future<AprendizProgressModel> getProgress();
}

class AprendizProfileRemoteDataSourceImpl implements AprendizProfileRemoteDataSource {
  final ApiClient apiClient;

  AprendizProfileRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AprendizProgressModel> getProgress() async {
    final response = await apiClient.get<AprendizProgressModel>(
      ApiEndpoints.profile.progress,
      fromJsonT: (json) => AprendizProgressModel.fromJson(json),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Error al obtener el progreso');
    }
    return response.data!;
  }
}
