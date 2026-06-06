import 'package:dio/dio.dart';
import '../models/treatment_model.dart';

abstract interface class TreatmentRemoteDataSource {
  Future<List<TreatmentModel>> getAgenda();
  Future<TreatmentModel> getById(String id);
  Future<void> markStepComplete({
    required String treatmentId,
    required String stepId,
  });
}

class TreatmentRemoteDataSourceImpl implements TreatmentRemoteDataSource {
  final Dio client;
  const TreatmentRemoteDataSourceImpl({required this.client});

  @override
  Future<List<TreatmentModel>> getAgenda() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      TreatmentModel(
        id: '1',
        diseaseName: 'Gusano cogollero',
        cropName: 'Maiz',
        totalSteps: 3,
        completedSteps: 1,
        remindersActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        steps: [
          TreatmentStepModel(
            id: 's1',
            stepNumber: 1,
            title: 'Aplicacion inicial',
            description: 'Aplicar insecticida de contacto al atardecer.',
            status: 'completado',
            scheduledDate: DateTime.now().subtract(const Duration(days: 3)),
            completedDate: DateTime.now().subtract(const Duration(days: 3)),
          ),
          TreatmentStepModel(
            id: 's2',
            stepNumber: 2,
            title: 'Refuerzo sistemico',
            description: 'Aplicacion de refuerzo para control de larvas.',
            status: 'programado',
            scheduledDate: DateTime.now().add(const Duration(days: 1)),
          ),
          TreatmentStepModel(
            id: 's3',
            stepNumber: 3,
            title: 'Monitoreo final',
            description: 'Verificar presencia de nuevas larvas.',
            status: 'pendiente',
            scheduledDate: DateTime.now().add(const Duration(days: 5)),
          ),
        ],
      )
    ];
  }

  @override
  Future<TreatmentModel> getById(String id) async {
    final agenda = await getAgenda();
    return agenda.first;
  }

  @override
  Future<void> markStepComplete({
    required String treatmentId,
    required String stepId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Simulando exito
  }
}
