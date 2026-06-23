import '../../../../core/network/api_client.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';

abstract class AprendizDiagnosisRemoteDataSource {
  Future<DiagnosisEntity> analyzeCrop({required String imagePath, String? description});
}

class AprendizDiagnosisRemoteDataSourceImpl implements AprendizDiagnosisRemoteDataSource {
  final ApiClient apiClient;

  AprendizDiagnosisRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<DiagnosisEntity> analyzeCrop({required String imagePath, String? description}) async {
    final response = await apiClient.post<DiagnosisEntity>(
      '/api/v1/diagnosis/analyze',
      data: {'imagePath': imagePath, if (description != null) 'description': description},
      fromJsonT: (json) {
        return DiagnosisEntity(
          id: json['id'] ?? '',
          diseaseName: json['diseaseName'] ?? 'Desconocida',
          cropName: json['cropName'] ?? '',
          confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
          diagnosedAt: json['diagnosedAt'] != null ? DateTime.parse(json['diagnosedAt']) : DateTime.now(),
          statusLabel: json['statusLabel'] ?? 'Seguimiento',
        );
      },
    );

    if (!response.success || response.data == null) {
      throw Exception('Error en el servidor');
    }

    return response.data!;
  }
}
