import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/agenda_activity_entity.dart';
import '../models/agenda_activity_model.dart';
import '../models/agenda_overview_model.dart';

/// Fuente remota del modulo Agenda.
///
/// El endpoint aun no esta expuesto por el backend (ver [ApiEndpoints.agenda]
/// / TODO en ese archivo). Los metodos ya estan implementados contra
/// [ApiClient] siguiendo el mismo patron que el resto de la app: cuando el
/// backend publique la URL real, esta clase no necesita cambios adicionales.
abstract class AgendaRemoteDataSource {
  Future<AgendaOverviewModel> getAgendaOverview();
  Future<AgendaActivityModel> completeActivity(String activityId);
  Future<AgendaActivityModel> postponeActivity(String activityId, String reason);
}

class AgendaRemoteDataSourceImpl implements AgendaRemoteDataSource {
  final ApiClient apiClient;

  AgendaRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AgendaOverviewModel> getAgendaOverview() async {
    final response = await apiClient.get<AgendaOverviewModel>(
      ApiEndpoints.agenda.overview,
      fromJsonT: (json) => AgendaOverviewModel.fromJson(json),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Error al obtener la agenda');
    }
    return response.data!;
  }

  @override
  Future<AgendaActivityModel> completeActivity(String activityId) async {
    final response = await apiClient.post<AgendaActivityModel>(
      ApiEndpoints.agenda.completeActivity(activityId),
      data: {'status': AgendaActivityStatus.completed.name},
      fromJsonT: (json) => AgendaActivityModel.fromJson(json),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Error al completar la actividad');
    }
    return response.data!;
  }

  @override
  Future<AgendaActivityModel> postponeActivity(String activityId, String reason) async {
    final response = await apiClient.post<AgendaActivityModel>(
      ApiEndpoints.agenda.postponeActivity(activityId),
      data: {'status': AgendaActivityStatus.postponed.name, 'reason': reason},
      fromJsonT: (json) => AgendaActivityModel.fromJson(json),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Error al posponer la actividad');
    }
    return response.data!;
  }
}
