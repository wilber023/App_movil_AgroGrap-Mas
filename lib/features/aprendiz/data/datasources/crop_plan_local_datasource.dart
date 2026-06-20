import 'package:hive/hive.dart';
import 'dart:convert';
import '../models/crop_plan_model.dart';
import '../models/crop_activity_model.dart';

abstract class CropPlanLocalDataSource {
  Future<void> cacheCropPlan(CropPlanModel plan);
  Future<CropPlanModel?> getCachedCropPlan();
  Future<void> cacheActivityUpdate(CropActivityModel activity);
}

class CropPlanLocalDataSourceImpl implements CropPlanLocalDataSource {
  final Box<String> box;
  static const _cachedPlanKey = 'CACHED_CROP_PLAN';

  CropPlanLocalDataSourceImpl({required this.box});

  @override
  Future<void> cacheCropPlan(CropPlanModel plan) async {
    await box.put(_cachedPlanKey, jsonEncode(plan.toJson()));
  }

  @override
  Future<CropPlanModel?> getCachedCropPlan() async {
    final jsonString = box.get(_cachedPlanKey);
    if (jsonString != null) {
      return CropPlanModel.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  @override
  Future<void> cacheActivityUpdate(CropActivityModel activity) async {
    // Para simplificar, actualizamos la actividad en el plan en cache y la marcamos como pendiente de sync
    final plan = await getCachedCropPlan();
    if (plan != null) {
      final updatedActivities = plan.activities.map((a) {
        if (a.id == activity.id) {
          return activity.copyWith(isPendingSync: true) as CropActivityModel;
        }
        return a;
      }).toList();
      
      final updatedPlan = CropPlanModel(
        id: plan.id,
        userId: plan.userId,
        cropName: plan.cropName,
        currentStage: plan.currentStage,
        startDate: plan.startDate,
        currentWeek: plan.currentWeek,
        progressPercentage: plan.progressPercentage,
        activities: updatedActivities,
        isPendingSync: plan.isPendingSync,
      );
      await cacheCropPlan(updatedPlan);
    }
  }
}
