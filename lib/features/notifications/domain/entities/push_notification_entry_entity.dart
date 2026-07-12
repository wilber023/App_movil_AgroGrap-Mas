import 'package:equatable/equatable.dart';

/// Una notificacion push recibida y guardada localmente (historial).
///
/// El backend de notificaciones no expone ningun endpoint de historial
/// (solo suscripcion, ver integrar_notificaciones.md) -- este historial es
/// 100% local, construido a partir de los mensajes FCM que efectivamente
/// llegaron a este dispositivo.
class PushNotificationEntryEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String? estado;
  final String? campania;
  final DateTime receivedAt;

  const PushNotificationEntryEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.estado,
    this.campania,
  });

  @override
  List<Object?> get props => [id, title, body, estado, campania, receivedAt];
}
