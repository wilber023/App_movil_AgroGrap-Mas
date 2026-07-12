import 'package:equatable/equatable.dart';

/// Suscripcion a alertas push tal como la reporta el microservicio de
/// notificaciones (ver integrar_notificaciones.md, seccion 2.2).
class NotificationSubscriptionEntity extends Equatable {
  final String userId;
  final String fcmToken;
  final String estado;
  final List<String> cultivos;
  final DateTime? creado;
  final DateTime? actualizado;

  const NotificationSubscriptionEntity({
    required this.userId,
    required this.fcmToken,
    required this.estado,
    this.cultivos = const [],
    this.creado,
    this.actualizado,
  });

  @override
  List<Object?> get props => [userId, fcmToken, estado, cultivos, creado, actualizado];
}
