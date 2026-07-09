import '../../domain/entities/agenda_crop_context_entity.dart';
import '../../domain/entities/agenda_overview_entity.dart';
import 'agenda_activity_model.dart';

class AgendaOverviewModel extends AgendaOverviewEntity {
  const AgendaOverviewModel({
    required super.cropContext,
    required List<AgendaActivityModel> super.activities,
  });

  factory AgendaOverviewModel.fromJson(Map<String, dynamic> json) {
    final cropContextJson = json['cropContext'] as Map<String, dynamic>;
    return AgendaOverviewModel(
      cropContext: AgendaCropContextEntity(
        cropName: cropContextJson['cropName'] as String,
        currentStage: cropContextJson['currentStage'] as String,
        currentWeek: cropContextJson['currentWeek'] as int,
      ),
      activities: (json['activities'] as List<dynamic>? ?? const [])
          .map((e) => AgendaActivityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cropContext': {
        'cropName': cropContext.cropName,
        'currentStage': cropContext.currentStage,
        'currentWeek': cropContext.currentWeek,
      },
      'activities': activities
          .map((e) => AgendaActivityModel.fromEntity(e).toJson())
          .toList(),
    };
  }
}
