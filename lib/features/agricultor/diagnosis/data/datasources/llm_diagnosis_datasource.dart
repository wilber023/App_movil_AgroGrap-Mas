// =============================================================================
// AgroGraph-MAS — DataSource LLM (POST /api/v1/consultar)
// =============================================================================

import 'package:dio/dio.dart';

import '../../domain/entities/diagnosis_entity.dart';
import '../../domain/entities/llm_response_entity.dart';

abstract class LlmDiagnosisDataSource {
  Future<LlmResponseEntity> consultar({
    required DiagnosisEntity diagnosis,
    required String rol,
    String? userText,
  });
}

class LlmDiagnosisDataSourceImpl implements LlmDiagnosisDataSource {
  final Dio _dio;

  LlmDiagnosisDataSourceImpl(this._dio);

  @override
  Future<LlmResponseEntity> consultar({
    required DiagnosisEntity diagnosis,
    required String rol,
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
      'rol': rol,
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

    // El backend extrae secciones en campos individuales Y envía respuesta.texto
    // (markdown completo). Priorizamos los campos individuales (texto limpio,
    // sin encabezados markdown); si llegan vacíos usamos extracción del texto.
    final texto = respuesta['texto'] as String? ?? '';

    String resolve(String key, String mdHeader) {
      final v = respuesta[key] as String? ?? '';
      return v.isNotEmpty ? v : _extractSection(texto, mdHeader);
    }

    final diagnostico = resolve('diagnostico', '### DIAGNÓSTICO');
    final tratamiento = resolve('tratamiento', '### TRATAMIENTO');
    final prevencion  = resolve('prevencion',  '### PREVENCIÓN');

    return LlmResponseEntity(
      // Último fallback: texto completo cuando ninguna extracción produce contenido.
      diagnostico: diagnostico.isNotEmpty ? diagnostico : texto,
      tratamiento: tratamiento,
      prevencion: prevencion,
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

  /// Extrae el contenido de una sección markdown identificada por [header].
  /// Devuelve '' si el encabezado no existe en el texto.
  static String _extractSection(String text, String header) {
    final start = text.indexOf(header);
    if (start == -1) return '';
    final afterHeader = text.indexOf('\n', start);
    if (afterHeader == -1) return '';
    final nextHeader = RegExp(r'^###\s', multiLine: true)
        .allMatches(text, afterHeader + 1)
        .firstOrNull
        ?.start ?? text.length;
    return text.substring(afterHeader + 1, nextHeader).trim();
  }
}
