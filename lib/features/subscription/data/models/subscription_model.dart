import '../../domain/entities/subscription_entity.dart';

class SubscriptionModel extends SubscriptionEntity {
  const SubscriptionModel({
    required super.id,
    required super.status,
    required super.planId,
    required super.planType,
    super.nextBillingTime,
    super.lastPaymentAmount,
    super.lastPaymentCurrency,
    super.lastPaymentTime,
    super.subscriberEmail,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final lastPayment = json['lastPayment'] is Map
        ? Map<String, dynamic>.from(json['lastPayment'] as Map)
        : const <String, dynamic>{};
    final subscriber = json['subscriber'] is Map
        ? Map<String, dynamic>.from(json['subscriber'] as Map)
        : const <String, dynamic>{};

    return SubscriptionModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'CANCELLED',
      planId: json['planId']?.toString() ?? '',
      planType: json['planType']?.toString() ?? 'free',
      nextBillingTime: DateTime.tryParse(json['nextBillingTime']?.toString() ?? ''),
      lastPaymentAmount: double.tryParse(lastPayment['amount']?.toString() ?? ''),
      lastPaymentCurrency: lastPayment['currency']?.toString(),
      lastPaymentTime: DateTime.tryParse(lastPayment['time']?.toString() ?? ''),
      subscriberEmail: subscriber['email']?.toString(),
    );
  }
}
