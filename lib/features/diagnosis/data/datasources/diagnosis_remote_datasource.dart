import '../../../../core/network/api_client.dart';
import '../../domain/entities/diagnosis_entity.dart';

abstract class DiagnosisRemoteDataSource {
  Future<DiagnosisEntity> analyzeCrop(String imagePath);
  Future<List<DiagnosisEntity>> getHistory();
}

class DiagnosisRemoteDataSourceImpl implements DiagnosisRemoteDataSource {
  final ApiClient apiClient;

  DiagnosisRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<DiagnosisEntity> analyzeCrop(String imagePath) async {
    // Aquí idealmente se subiría la imagen (multipart/form-data)
    // Para simplificar según contrato, enviamos json si estuviera en base64
    // o asume que el backend procesa la ruta si se subió antes.
    final response = await apiClient.post<DiagnosisEntity>(
      '/api/v1/diagnosis/analyze',
      data: {'imagePath': imagePath},
      fromJsonT: (json) => _parseDiagnosis(json),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Error en el diagnóstico');
    }
    return response.data!;
  }

  @override
  Future<List<DiagnosisEntity>> getHistory() async {
    final response = await apiClient.get<List<DiagnosisEntity>>(
      '/api/v1/diagnosis/history',
      fromJsonT: (json) => (json as List).map((e) => _parseDiagnosis(e)).toList(),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Error al obtener historial');
    }
    return response.data!;
  }

  DiagnosisEntity _parseDiagnosis(dynamic json) {
    return DiagnosisEntity(
      id: json['id'] ?? '',
      diseaseName: json['diseaseName'] ?? 'Desconocida',
      cropName: json['cropName'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      diagnosedAt: json['diagnosedAt'] != null ? DateTime.parse(json['diagnosedAt']) : DateTime.now(),
      statusLabel: json['statusLabel'] ?? 'Seguimiento',
    );
  }
}
