import 'package:equatable/equatable.dart';

/// A que modulo debe navegar el botón de la tarjeta de recomendación.
enum RecommendationAction { registerCrop, diagnosis, agenda, none }

/// Recomendación personalizada mostrada en el Perfil, calculada con reglas
/// simples sobre datos reales (ver `AprendizProfileLocalDataSourceImpl`).
class AprendizRecommendationEntity extends Equatable {
  final String title;
  final String description;
  final String actionLabel;
  final RecommendationAction action;

  const AprendizRecommendationEntity({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.action,
  });

  @override
  List<Object?> get props => [title, description, actionLabel, action];
}
