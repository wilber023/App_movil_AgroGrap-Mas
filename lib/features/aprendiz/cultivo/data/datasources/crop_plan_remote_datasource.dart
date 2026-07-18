import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/api_endpoints.dart';
import '../models/crop_plan_model.dart';
import '../../domain/entities/crop_health_entity.dart';
import '../models/crop_activity_model.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../../domain/entities/crop_practice_location.dart';

abstract class CropPlanRemoteDataSource {
  Future<CropPlanModel> getSavedCropPlan();
  Future<CropPlanModel> registerCropPlan({
    required String cropName,
    required DateTime startDate,
    required CropPracticeLocation practiceLocation,
  });
  Future<CropHealthEntity> getCropHealthIndicator();
  Future<CropActivityModel> updateActivityStatus(String activityId, ActivityStatus status, String? reason);
}

class CropPlanRemoteDataSourceImpl implements CropPlanRemoteDataSource {
  final ApiClient apiClient;

  CropPlanRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<CropPlanModel> getSavedCropPlan() async {
    final response = await apiClient.get<CropPlanModel>(
      ApiEndpoints.aprendiz.cropPlan,
      fromJsonT: (json) => CropPlanModel.fromJson(json),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Error al obtener el plan');
    }
    return response.data!;
  }

  @override
  Future<CropPlanModel> registerCropPlan({
    required String cropName,
    required DateTime startDate,
    required CropPracticeLocation practiceLocation,
  }) async {
    final response = await apiClient.post<CropPlanModel>(
      ApiEndpoints.aprendiz.cropPlan,
      data: {
        'cropName': cropName,
        'startDate': startDate.toIso8601String(),
        'practiceLocation': practiceLocation.name,
      },
      fromJsonT: (json) => CropPlanModel.fromJson(json),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Error al registrar el plan');
    }
    return response.data!;
  }

  @override
  Future<CropHealthEntity> getCropHealthIndicator() async {
    final response = await apiClient.get<CropHealthEntity>(
      ApiEndpoints.aprendiz.cropHealth,
      fromJsonT: (json) => CropHealthEntity(
        status: json['status'],
        healthyPlantsPercentage: json['healthyPlantsPercentage'],
        affectedPlantsPercentage: json['affectedPlantsPercentage'],
        lastInspectionDate: DateTime.parse(json['lastInspectionDate']),
      ),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Error al obtener salud');
    }
    return response.data!;
  }

  @override
  Future<CropActivityModel> updateActivityStatus(String activityId, ActivityStatus status, String? reason) async {
    final response = await apiClient.post<CropActivityModel>(
      ApiEndpoints.aprendiz.activityStatus(activityId),
      data: {'status': status.name, 'reason': reason},
      fromJsonT: (json) => CropActivityModel.fromJson(json),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Error al actualizar actividad');
    }
    return response.data!;
  }
}
