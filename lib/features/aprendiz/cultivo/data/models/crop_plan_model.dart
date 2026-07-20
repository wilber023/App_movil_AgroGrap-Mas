import '../../domain/entities/crop_plan_entity.dart';
import 'crop_activity_model.dart';

class CropPlanModel extends CropPlanEntity {
  /// Total de semanas del ciclo de cultivo usado para estimar la semana
  /// actual (mismo criterio que `_kTotalCropWeeks` en la Ruta del Cultivo).
  static const int totalCropWeeks = 18;

  const CropPlanModel({
    required super.id,
    required super.userId,
    required super.cropName,
    required super.currentStage,
    required super.startDate,
    required super.currentWeek,
    required super.progressPercentage,
    required super.activities,
    super.isPendingSync,
  });

  /// Parsea la respuesta real del microservicio de Cultivos
  /// (`POST /selecciones` o un elemento de `GET /selecciones/mis-selecciones`),
  /// ver `README_FRONTEND_APRENDIZ_SIEMBRA.md` sección 4.1.
  ///
  /// El backend aún no genera un plan de actividades ni expone la semana
  /// actual del ciclo (sección 3, pregunta 4 del mismo README) -- se
  /// estima la semana a partir de `fecha_siembra` y las actividades
  /// quedan vacías hasta que ese endpoint exista.
  factory CropPlanModel.fromSeleccionJson(Map<String, dynamic> json) {
    final startDate = DateTime.tryParse(json['fecha_siembra']?.toString() ?? '') ??
        DateTime.now();
    return CropPlanModel(
      id: json['id']?.toString() ?? '',
      userId: json['usuario_id']?.toString() ?? '',
      cropName: json['cultivo_nombre']?.toString() ?? 'Cultivo de práctica',
      currentStage: json['etapa_fenologica']?.toString() ?? 'Siembra',
      startDate: startDate,
      currentWeek: _estimateWeek(startDate),
      progressPercentage: (json['progreso_etapa'] as num?)?.toDouble() ?? 0,
      activities: const [],
    );
  }

  static int _estimateWeek(DateTime startDate) {
    final elapsedDays = DateTime.now().difference(startDate).inDays;
    final week = (elapsedDays / 7).floor() + 1;
    return week.clamp(1, totalCropWeeks).toInt();
  }

  factory CropPlanModel.fromJson(Map<String, dynamic> json) {
    return CropPlanModel(
      id: json['id'],
      userId: json['userId'],
      cropName: json['cropName'],
      currentStage: json['currentStage'],
      startDate: DateTime.parse(json['startDate']),
      currentWeek: json['currentWeek'],
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
      activities: (json['activities'] as List<dynamic>?)
              ?.map((e) => CropActivityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isPendingSync: json['isPendingSync'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'cropName': cropName,
      'currentStage': currentStage,
      'startDate': startDate.toIso8601String(),
      'currentWeek': currentWeek,
      'progressPercentage': progressPercentage,
      'activities': activities
          .map((a) => CropActivityModel.fromEntity(a).toJson())
          .toList(),
      'isPendingSync': isPendingSync,
    };
  }
}
