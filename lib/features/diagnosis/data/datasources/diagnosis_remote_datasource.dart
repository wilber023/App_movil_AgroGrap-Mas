import 'package:dio/dio.dart';
import '../models/diagnosis_model.dart';

abstract interface class DiagnosisRemoteDataSource {
  Future<DiagnosisModel> analyzeCrop({required String imagePath});
  Future<List<DiagnosisHistoryItemModel>> getHistory();
  Future<DiagnosisModel> getById(String id);
}

class DiagnosisRemoteDataSourceImpl implements DiagnosisRemoteDataSource {
  final Dio client;
  const DiagnosisRemoteDataSourceImpl({required this.client});

  @override
  Future<DiagnosisModel> analyzeCrop({required String imagePath}) async {
    await Future.delayed(const Duration(seconds: 2));
    return DiagnosisModel(
      id: 'd1',
      diseaseName: 'Tizon temprano',
      cropName: 'Papa',
      severity: 'alta',
      confidence: 0.92,
      description: 'Manchas foliares oscuras con anillos concentricos. Posible inicio de infeccion severa.',
      diagnosedAt: DateTime.now(),
      recommendations: const [
        'Aislar las plantas afectadas inmediatamente.',
        'Aplicar fungicida a base de cobre.',
        'Reducir la humedad del suelo evitando el riego nocturno.'
      ],
    );
  }

  @override
  Future<List<DiagnosisHistoryItemModel>> getHistory() async {
    return [];
  }

  @override
  Future<DiagnosisModel> getById(String id) async {
    return analyzeCrop(imagePath: 'dummy');
  }
}
