// =============================================================================
// AgroGraph-MAS — DataSource LLM (POST /api/v1/consultar)
// =============================================================================

import 'package:dio/dio.dart';

import '../../domain/entities/diagnosis_entity.dart';
import '../../domain/entities/llm_response_entity.dart';

abstract class LlmDiagnosisDataSource {
  Future<LlmResponseEntity> consultar({
    required DiagnosisEntity diagnosis,
    String? userText,
  });
}

class LlmDiagnosisDataSourceImpl implements LlmDiagnosisDataSource {
  final Dio _dio;

  LlmDiagnosisDataSourceImpl(this._dio);

  @override
  Future<LlmResponseEntity> consultar({
    required DiagnosisEntity diagnosis,
    String? userText,
  }) async {
    final claseCnn = diagnosis.topK.isNotEmpty
        ? diagnosis.topK.first.rawLabel
        : '${diagnosis.cropName} ${diagnosis.diseaseName}';

    final body = <String, dynamic>{
      'resultado_cnn': {
        'cultivo': diagnosis.cropName.toLowerCase(),
        'enfermedad': diagnosis.diseaseName.toLowerCase(),
        'confianza': diagnosis.confidence,
        'clase_cnn': claseCnn,
        'confianza_baja': diagnosis.confidence < 0.50,
      },
      'cultivos': [diagnosis.cropName.toLowerCase()],
    };

    if (userText != null && userText.trim().isNotEmpty) {
      body['texto'] = userText.trim();
    }

    final response = await _dio.post('/api/v1/consultar', data: body);
    return _parse(response.data as Map<String, dynamic>);
  }

  LlmResponseEntity _parse(Map<String, dynamic> json) {
    final respuesta = (json['respuesta'] as Map<String, dynamic>?) ?? {};
    final diag = (json['diagnostico'] as Map<String, dynamic>?) ?? {};
    final sintomas = (json['sintomas'] as List<dynamic>? ?? []).cast<String>();
    final avisos = (json['avisos'] as List<dynamic>? ?? []).cast<String>();
    final fuentes = (respuesta['fuentes'] as List<dynamic>? ?? []).cast<String>();

    return LlmResponseEntity(
      diagnostico: respuesta['diagnostico'] as String? ?? '',
      tratamiento: respuesta['tratamiento'] as String? ?? '',
      prevencion: respuesta['prevencion'] as String? ?? '',
      fuentes: fuentes,
      confianzaAjustada:
          (diag['confianza_ajustada'] as num?)?.toDouble() ?? 0.0,
      estado: diag['estado'] as String? ?? '',
      explicacion: diag['explicacion'] as String? ?? '',
      sintomas: sintomas,
      avisos: avisos,
      sinDocumentos: respuesta['sin_documentos'] as bool? ?? false,
    );
  }
}
