import 'package:equatable/equatable.dart';

/// A donde debe navegar el usuario si toca la recomendacion del dia
/// (cuando aplica — no todas las recomendaciones tienen accion).
enum HomeRecommendationAction { registerCrop, diagnosis, none }

/// Recomendacion del dia. Hoy se deriva con una regla simple sobre datos
/// reales (ver `AprendizHomeRepositoryImpl`); la estructura ya queda lista
/// para que en el futuro el mensaje venga de la API.
class HomeRecommendationEntity extends Equatable {
  final String message;
  final HomeRecommendationAction action;

  const HomeRecommendationEntity({required this.message, required this.action});

  @override
  List<Object?> get props => [message, action];
}
