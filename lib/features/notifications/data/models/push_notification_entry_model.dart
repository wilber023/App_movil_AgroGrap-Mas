import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/entities/push_notification_entry_entity.dart';

class PushNotificationEntryModel extends PushNotificationEntryEntity {
  const PushNotificationEntryModel({
    required super.id,
    required super.title,
    required super.body,
    required super.receivedAt,
    super.estado,
    super.campania,
  });

  /// Construye la entrada a partir de un [RemoteMessage] de FCM. Se usa
  /// tanto desde el listener en foreground/background (isolate principal)
  /// como desde el background handler (isolate separado) -- una sola
  /// fuente de verdad para el parseo, evita duplicar logica.
  factory PushNotificationEntryModel.fromRemoteMessage(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Alerta fitosanitaria';
    final body = message.notification?.body ?? message.data['body']?.toString() ?? '';
    final estado = message.data['estado']?.toString();
    final campania = message.data['campania']?.toString();
    final receivedAt = message.sentTime ?? DateTime.now();

    return PushNotificationEntryModel(
      id: _dedupKey(
        messageId: message.messageId,
        title: title,
        body: body,
        receivedAt: receivedAt,
      ),
      title: title,
      body: body,
      estado: estado,
      campania: campania,
      receivedAt: receivedAt,
    );
  }

  factory PushNotificationEntryModel.fromJson(Map<String, dynamic> json) {
    return PushNotificationEntryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      estado: json['estado']?.toString(),
      campania: json['campania']?.toString(),
      receivedAt: DateTime.tryParse(json['receivedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'estado': estado,
        'campania': campania,
        'receivedAt': receivedAt.toIso8601String(),
      };

  /// Id estable para dedup: usa el `messageId` de FCM si vino presente
  /// (no siempre lo trae), o un hash de titulo+cuerpo+fecha en su defecto.
  /// Al guardarse con `Box.put(id, ...)` (create-or-overwrite), el mismo
  /// mensaje llegando por mas de un listener (foreground/background/tap)
  /// nunca genera una entrada duplicada.
  static String _dedupKey({
    required String? messageId,
    required String title,
    required String body,
    required DateTime receivedAt,
  }) {
    if (messageId != null && messageId.isNotEmpty) return messageId;
    final bucket = receivedAt.toIso8601String().substring(0, 16); // minuto
    return '$title|$body|$bucket'.hashCode.toRadixString(16);
  }
}
