import '../../domain/entities/subscribe_result_entity.dart';

class SubscribeResultModel extends SubscribeResultEntity {
  const SubscribeResultModel({
    required super.subscriptionId,
    required super.approveUrl,
    required super.status,
  });

  factory SubscribeResultModel.fromJson(Map<String, dynamic> json) {
    return SubscribeResultModel(
      subscriptionId: json['subscriptionId']?.toString() ?? '',
      approveUrl: json['approveUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? 'APPROVAL_PENDING',
    );
  }
}
