import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/agenda_activity_entity.dart';
import '../../domain/entities/agenda_crop_context_entity.dart';
import '../models/agenda_activity_model.dart';
import '../models/agenda_overview_model.dart';

/// Fuente local (offline-first) del modulo Agenda.
///
/// Usa una caja Hive propia (ver `agenda_injection_container.dart`), separada
/// de la caja de Mi Cultivo, para no acoplar ambos modulos.
///
/// Mientras el backend de Agenda no exista, [getCachedOverview] siembra una
/// unica vez datos base (`_seedOverview`) para que la pantalla no quede
/// vacia. Ese seed vive exclusivamente aqui: ni el BLoC ni los widgets lo
/// conocen, y se reemplaza automaticamente en cuanto haya datos reales
/// cacheados desde el remoto.
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
    final seed = _seedOverview();
    await cacheOverview(seed);
    return seed;
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

  /// Datos base de arranque, calculados en relacion a la fecha actual para
  /// que la Agenda siempre muestre "Hoy" correctamente. Se reemplazan por
  /// datos reales del backend en cuanto el modulo remoto quede disponible.
  AgendaOverviewModel _seedOverview() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return AgendaOverviewModel(
      cropContext: const AgendaCropContextEntity(
        cropName: 'Calabaza',
        currentStage: 'Desarrollo Vegetativo',
        currentWeek: 6,
      ),
      activities: [
        AgendaActivityModel(
          id: 'seed-today',
          title: 'Desarrollo Vegetativo',
          description: 'En esta etapa tu planta esta creciendo sus hojas y tallos.',
          checklist: const [
            'Revisa la aparicion de nuevas hojas',
            'Controla la maleza alrededor de la planta',
            'Verifica que el suelo este humedo',
          ],
          scheduledDate: today,
          weekNumber: 6,
          status: AgendaActivityStatus.pending,
          category: AgendaActivityCategory.tracking,
        ),
        AgendaActivityModel(
          id: 'seed-upcoming-1',
          title: 'Seguimiento y revision',
          description: 'Verificar respuesta de la planta a los cuidados de la semana.',
          scheduledDate: today.add(const Duration(days: 7)),
          weekNumber: 7,
          status: AgendaActivityStatus.pending,
          category: AgendaActivityCategory.tracking,
        ),
        AgendaActivityModel(
          id: 'seed-upcoming-2',
          title: 'Nueva inspeccion con foto',
          description: 'Inspeccion fotografica programada para diagnostico.',
          scheduledDate: today.add(const Duration(days: 14)),
          weekNumber: 8,
          status: AgendaActivityStatus.pending,
          category: AgendaActivityCategory.inspection,
        ),
      ],
    );
  }
}
