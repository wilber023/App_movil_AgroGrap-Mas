import 'package:equatable/equatable.dart';

/// Resultado de `POST /subscribe`: la URL donde el usuario aprueba el pago.
class SubscribeResultEntity extends Equatable {
  final String subscriptionId;
  final String approveUrl;
  final String status;

  const SubscribeResultEntity({
    required this.subscriptionId,
    required this.approveUrl,
    required this.status,
  });

  @override
  List<Object?> get props => [subscriptionId, approveUrl, status];
}
