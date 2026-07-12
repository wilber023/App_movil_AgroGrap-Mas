// =============================================================================
// AgroGraph-MAS — Ficha de tratamiento offline (features/offline_knowledge)
// Ver agrograph_diagnostico_offline_embeddings.md, sección 4 y 8.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Una ficha del paquete de conocimiento offline de un cultivo.
///
/// El campo [id] debe estar sincronizado 1:1 con las clases de salida del
/// modelo CNN (raw label). Ver sección 8 del documento de especificación.
class TreatmentEntry extends Equatable {
  final String id;
  final String cultivo;
  final String enfermedad;
  final String sintomas;
  final String tratamiento;
  final String severidad;
  final List<double> embedding;

  const TreatmentEntry({
    required this.id,
    required this.cultivo,
    required this.enfermedad,
    required this.sintomas,
    required this.tratamiento,
    required this.severidad,
    required this.embedding,
  });

  @override
  List<Object?> get props => [
    id,
    cultivo,
    enfermedad,
    sintomas,
    tratamiento,
    severidad,
    embedding,
  ];
}
