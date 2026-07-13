import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/agenda_crop_context_entity.dart';
import '../models/agenda_activity_model.dart';
import '../models/agenda_overview_model.dart';

/// Fuente local (offline-first) del modulo Agenda.
///
/// Reutilizable por Agricultor y Aprendiz: cada uno registra su propia
/// instancia con su propia caja Hive (ver `agenda_injection_container.dart`
/// y `_initTreatmentFeature()`).
///
/// Si nunca se genero ni se cacheo una agenda real, [getCachedOverview]
/// devuelve el mismo "vacio" que ya usa el backend para un usuario nuevo
/// (`cropName`/`currentStage` vacios, sin actividades) -- nunca datos de
/// ejemplo inventados.
abstract class AgendaLocalDataSource {
  Future<void> cacheOverview(AgendaOverviewModel overview);
  Future<AgendaOverviewModel> getCachedOverview();
  Future<AgendaActivityModel> applyActivityUpdate(AgendaActivityModel activity);
}

class AgendaLocalDataSourceImpl implements AgendaLocalDataSource {
  final Box<String> box;
  static const _cachedOverviewKey = 'CACHED_AGENDA_OVERVIEW';

  AgendaLocalDataSourceImpl({required this.box});

  @override
  Future<void> cacheOverview(AgendaOverviewModel overview) async {
    await box.put(_cachedOverviewKey, jsonEncode(overview.toJson()));
  }

  @override
  Future<AgendaOverviewModel> getCachedOverview() async {
    final jsonString = box.get(_cachedOverviewKey);
    if (jsonString != null) {
      return AgendaOverviewModel.fromJson(jsonDecode(jsonString));
    }
    return _empty;
  }

  @override
  Future<AgendaActivityModel> applyActivityUpdate(AgendaActivityModel activity) async {
    final overview = await getCachedOverview();
    final updatedActivities = overview.activities.map((a) {
      return a.id == activity.id ? activity : AgendaActivityModel.fromEntity(a);
    }).toList();

    final updatedOverview = AgendaOverviewModel(
      cropContext: overview.cropContext,
      activities: updatedActivities,
    );
    await cacheOverview(updatedOverview);
    return activity;
  }

  /// Mismo "vacio" que devuelve el backend para un usuario que aun no ha
  /// generado ninguna agenda (verificado con curl -- ver
  /// agenda_backend_implementacion.md).
  static const _empty = AgendaOverviewModel(
    cropContext: AgendaCropContextEntity(cropName: '', currentStage: '', currentWeek: 0),
    activities: [],
  );
}
