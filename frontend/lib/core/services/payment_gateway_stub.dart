import 'payment_result.dart';

Future<PaymentResult> openPlatformCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String userEmail,
  String? userPhone,
  String? userName,
  String? description,
}) async {
  return PaymentResult.failure('Payments are not supported on this platform.');
}
