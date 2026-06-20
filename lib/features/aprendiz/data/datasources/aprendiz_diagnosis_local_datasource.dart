import 'dart:convert';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';

abstract class AprendizDiagnosisLocalDataSource {
  Future<DiagnosisEntity> analyzeCropOffline({required String imagePath, String? description});
}

class AprendizDiagnosisLocalDataSourceImpl implements AprendizDiagnosisLocalDataSource {
  @override
  Future<DiagnosisEntity> analyzeCropOffline({required String imagePath, String? description}) async {
    // Simular tiempo de inferencia del modelo local
    await Future.delayed(const Duration(seconds: 3));

    // Simulación de JSON (Mock Data)
    final String mockJsonString = '''
    {
      "id": "mock_offline_\${DateTime.now().millisecondsSinceEpoch}",
      "diseaseName": "Gusano Cogollero",
      "scientificName": "Spodoptera frugiperda",
      "cropName": "Maíz",
      "parcelName": "Parcela Principal",
      "severity": "Moderada",
      "confidence": 0.88,
      "description": "Se detectaron daños foliares en el cogollo (Simulación Local).",
      "recommendationsWhatIs": [
        "Plaga común en la etapa vegetativa del maíz."
      ],
      "recommendationsWhatToDo": [
        "Aplicar extracto de neem.",
        "Monitorear la evolución en 3 días."
      ],
      "recommendationsNoAction": "Pérdida significativa de área foliar y reducción del rendimiento final.",
      "statusLabel": "Pendiente de Sincronización"
    }
    ''';

    final Map<String, dynamic> json = jsonDecode(mockJsonString);

    return DiagnosisEntity(
      id: json['id'] ?? '',
      diseaseName: json['diseaseName'] ?? 'Desconocida',
      scientificName: json['scientificName'] ?? '',
      cropName: json['cropName'] ?? '',
      parcelName: json['parcelName'] ?? '',
      severity: json['severity'] ?? 'Moderada',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      description: description != null && description.isNotEmpty ? description : json['description'] ?? '',
      recommendationsWhatIs: (json['recommendationsWhatIs'] as List?)?.map((e) => e.toString()).toList() ?? [],
      recommendationsWhatToDo: (json['recommendationsWhatToDo'] as List?)?.map((e) => e.toString()).toList() ?? [],
      recommendationsNoAction: json['recommendationsNoAction'] ?? '',
      diagnosedAt: DateTime.now(),
      statusLabel: json['statusLabel'] ?? 'Pendiente',
    );
  }
}
