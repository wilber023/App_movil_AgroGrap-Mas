// =============================================================================
// AgroGraph-MAS — Resultado de búsqueda por similitud (offline_knowledge)
// =============================================================================

import 'package:equatable/equatable.dart';

import 'treatment_entry.dart';

/// Una [TreatmentEntry] junto con su score de similitud coseno frente a un
/// vector de búsqueda. Devuelto por `KnowledgeRepository.searchBySimilarity`.
class ScoredEntry extends Equatable {
  final TreatmentEntry ficha;
  final double score;

  const ScoredEntry({required this.ficha, required this.score});

  @override
  List<Object?> get props => [ficha, score];
}
