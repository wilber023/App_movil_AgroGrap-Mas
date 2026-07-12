import '../../domain/entities/notification_subscription_entity.dart';

class NotificationSubscriptionModel extends NotificationSubscriptionEntity {
  const NotificationSubscriptionModel({
    required super.userId,
    required super.fcmToken,
    required super.estado,
    super.cultivos,
    super.creado,
    super.actualizado,
  });

  factory NotificationSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final cultivosJson = json['cultivos'];
    return NotificationSubscriptionModel(
      userId: json['user_id']?.toString() ?? '',
      fcmToken: json['fcm_token']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      cultivos: cultivosJson is List
          ? cultivosJson.map((e) => e.toString()).toList()
          : const [],
      creado: DateTime.tryParse(json['creado']?.toString() ?? ''),
      actualizado: DateTime.tryParse(json['actualizado']?.toString() ?? ''),
    );
  }
}
