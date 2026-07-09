import '../../../agricultor/diagnosis/data/services/cnn_engine.dart';
import '../../../agricultor/diagnosis/domain/entities/diagnosis_entity.dart';

abstract class AprendizDiagnosisLocalDataSource {
  Future<DiagnosisEntity> analyzeCropOffline({required String imagePath, String? description});
}

class AprendizDiagnosisLocalDataSourceImpl implements AprendizDiagnosisLocalDataSource {
  @override
  Future<DiagnosisEntity> analyzeCropOffline({
    required String imagePath,
    String? description,
  }) async {
    // Inferencia CNN real — mismo motor que usa el perfil agricultor
    final cnn = await CnnEngine.analyze(imagePath);

    final isHealthy = cnn.diseaseName.toLowerCase().contains('saludable') ||
        cnn.diseaseName.toLowerCase().contains('healthy');

    return DiagnosisEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      diseaseName: cnn.diseaseName,
      cropName: cnn.cropName,
      confidence: cnn.confidence,
      imagePath: imagePath,
      diagnosedAt: DateTime.now(),
      isPendingSync: true,
      statusLabel: isHealthy ? 'Saludable' : 'Seguimiento',
      topK: cnn.topK,
    );
  }
}
