import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../models/crop_event_model.dart';

abstract class CropHistoryRemoteDataSource {
  Future<List<CropEventModel>> getCropHistory();
}

class CropHistoryRemoteDataSourceImpl implements CropHistoryRemoteDataSource {
  final ApiClient apiClient;

  CropHistoryRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<CropEventModel>> getCropHistory() async {
    final response = await apiClient.get<List<CropEventModel>>(
      ApiEndpoints.aprendiz.history,
      fromJsonT: (json) => (json as List).map((e) => CropEventModel.fromJson(e)).toList(),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Error al obtener el historial');
    }
    return response.data!;
  }
}
