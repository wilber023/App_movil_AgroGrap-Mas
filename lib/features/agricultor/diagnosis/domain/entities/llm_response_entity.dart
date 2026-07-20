// =============================================================================
// AgroGraph-MAS — Entidad de respuesta del servicio LLM/RAG
// =============================================================================

class LlmResponseEntity {
  final String diagnostico;
  final String tratamiento;
  final String prevencion;
  final String aprendizaje;
  final List<String> fuentes;
  final double confianzaAjustada;
  /// "reforzado" | "posible_contradiccion" | "sin_senal_textual"
  final String estado;
  final String explicacion;
  final List<String> sintomas;
  final List<String> avisos;
  final bool sinDocumentos;

  const LlmResponseEntity({
    required this.diagnostico,
    required this.tratamiento,
    required this.prevencion,
    required this.aprendizaje,
    required this.fuentes,
    required this.confianzaAjustada,
    required this.estado,
    required this.explicacion,
    required this.sintomas,
    required this.avisos,
    required this.sinDocumentos,
  });

  Map<String, dynamic> toJson() => {
        'diagnostico': diagnostico,
        'tratamiento': tratamiento,
        'prevencion': prevencion,
        'aprendizaje': aprendizaje,
        'fuentes': fuentes,
        'confianzaAjustada': confianzaAjustada,
        'estado': estado,
        'explicacion': explicacion,
        'sintomas': sintomas,
        'avisos': avisos,
        'sinDocumentos': sinDocumentos,
      };

  factory LlmResponseEntity.fromJson(Map<String, dynamic> json) =>
      LlmResponseEntity(
        diagnostico: json['diagnostico'] as String? ?? '',
        tratamiento: json['tratamiento'] as String? ?? '',
        prevencion: json['prevencion'] as String? ?? '',
        aprendizaje: json['aprendizaje'] as String? ?? '',
        fuentes:
            (json['fuentes'] as List<dynamic>? ?? []).cast<String>(),
        confianzaAjustada:
            (json['confianzaAjustada'] as num?)?.toDouble() ?? 0.0,
        estado: json['estado'] as String? ?? '',
        explicacion: json['explicacion'] as String? ?? '',
        sintomas:
            (json['sintomas'] as List<dynamic>? ?? []).cast<String>(),
        avisos: (json['avisos'] as List<dynamic>? ?? []).cast<String>(),
        sinDocumentos: json['sinDocumentos'] as bool? ?? false,
      );
}
