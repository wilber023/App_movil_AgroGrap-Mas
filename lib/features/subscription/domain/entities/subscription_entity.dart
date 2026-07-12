import 'package:equatable/equatable.dart';

/// Estado de una suscripcion PayPal tal como lo reporta el backend.
///
/// Ver API.md > "Estados posibles de status".
class SubscriptionEntity extends Equatable {
  final String id;
  final String status; // ACTIVE | APPROVAL_PENDING | CANCELLED | SUSPENDED
  final String planId;
  final String planType; // monthly | yearly | free
  final DateTime? nextBillingTime;
  final double? lastPaymentAmount;
  final String? lastPaymentCurrency;
  final DateTime? lastPaymentTime;
  final String? subscriberEmail;

  const SubscriptionEntity({
    required this.id,
    required this.status,
    required this.planId,
    required this.planType,
    this.nextBillingTime,
    this.lastPaymentAmount,
    this.lastPaymentCurrency,
    this.lastPaymentTime,
    this.subscriberEmail,
  });

  bool get isActive => status == 'ACTIVE';

  @override
  List<Object?> get props => [
        id,
        status,
        planId,
        planType,
        nextBillingTime,
        lastPaymentAmount,
        lastPaymentCurrency,
        lastPaymentTime,
        subscriberEmail,
      ];
}
