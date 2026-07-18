// =============================================================================
// AgroGraph-MAS — DiagnosisDetail (offline_knowledge)
// Ver agrograph_diagnostico_offline_embeddings.md, secciones 4 y 7.
// =============================================================================

import 'package:equatable/equatable.dart';

import 'treatment_entry.dart';

/// Fuente del resultado devuelto por [GetOfflineDiagnosisDetailUseCase].
///
/// Determina el tono visual y el texto mostrado en la UI (ver sección 7.1
/// del documento de especificación).
enum DiagnosisSource { exactMatch, semanticFallback, notFound, packageMissing }

/// Resultado sellado del flujo de diagnóstico offline.
///
/// Siempre hay exactamente un estado activo, replicando la tabla de la
/// sección 7.1: [DiagnosisDetailExact], [DiagnosisDetailApproximate],
/// [DiagnosisDetailNotFound] o [DiagnosisDetailPackageMissing].
sealed class DiagnosisDetail extends Equatable {
  final String enfermedad;
  final String sintomas;
  final String tratamiento;
  final String severidad;
  final DiagnosisSource source;

  const DiagnosisDetail({
    required this.enfermedad,
    required this.sintomas,
    required this.tratamiento,
    required this.severidad,
    required this.source,
  });

  factory DiagnosisDetail.exact(TreatmentEntry ficha, double confianzaCnn) =>
      DiagnosisDetailExact(ficha: ficha, confianzaCnn: confianzaCnn);

  factory DiagnosisDetail.approximate(TreatmentEntry ficha, double score) =>
      DiagnosisDetailApproximate(ficha: ficha, score: score);

  factory DiagnosisDetail.notFound(String enfermedadId) =>
      DiagnosisDetailNotFound(enfermedadId: enfermedadId);

  factory DiagnosisDetail.packageMissing(String cultivo) =>
      DiagnosisDetailPackageMissing(cultivo: cultivo);

  @override
  List<Object?> get props => [
    enfermedad,
    sintomas,
    tratamiento,
    severidad,
    source,
  ];
}

/// Match exacto por ID — ficha completa, sin advertencia (95%+ de los casos).
final class DiagnosisDetailExact extends DiagnosisDetail {
  final TreatmentEntry ficha;
  final double confianzaCnn;

  DiagnosisDetailExact({required this.ficha, required this.confianzaCnn})
    : super(
        enfermedad: ficha.enfermedad,
        sintomas: ficha.sintomas,
        tratamiento: ficha.tratamiento,
        severidad: ficha.severidad,
        source: DiagnosisSource.exactMatch,
      );
}

/// Fallback semántico exitoso (score >= umbral) — ficha aproximada.
final class DiagnosisDetailApproximate extends DiagnosisDetail {
  final TreatmentEntry ficha;
  final double score;

  DiagnosisDetailApproximate({required this.ficha, required this.score})
    : super(
        enfermedad: ficha.enfermedad,
        sintomas: ficha.sintomas,
        tratamiento: ficha.tratamiento,
        severidad: ficha.severidad,
        source: DiagnosisSource.semanticFallback,
      );
}

/// Paquete descargado pero sin match usable (score < umbral).
final class DiagnosisDetailNotFound extends DiagnosisDetail {
  final String enfermedadId;

  const DiagnosisDetailNotFound({required this.enfermedadId})
    : super(
        enfermedad: enfermedadId,
        sintomas: '',
        tratamiento: '',
        severidad: '',
        source: DiagnosisSource.notFound,
      );
}

/// No hay paquete offline descargado para el cultivo detectado.
final class DiagnosisDetailPackageMissing extends DiagnosisDetail {
  final String cultivo;

  const DiagnosisDetailPackageMissing({required this.cultivo})
    : super(
        enfermedad: '',
        sintomas: '',
        tratamiento: '',
        severidad: '',
        source: DiagnosisSource.packageMissing,
      );
}
