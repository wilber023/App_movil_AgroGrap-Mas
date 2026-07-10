import 'package:equatable/equatable.dart';

/// Origen del aviso importante, para poder darle icono/acción propia si
/// hace falta en el futuro.
enum HomeNoticeType { dueInspection, noCropPlan }

/// Aviso importante mostrado en la tarjeta de "Avisos importantes". La
/// lista de avisos se arma dinamicamente (0, 1 o varios) a partir de
/// señales reales — ver `AprendizHomeRepositoryImpl`.
class HomeNoticeEntity extends Equatable {
  final HomeNoticeType type;
  final String message;

  const HomeNoticeEntity({required this.type, required this.message});

  @override
  List<Object?> get props => [type, message];
}
