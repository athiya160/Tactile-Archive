import 'payment_result.dart';
export 'payment_result.dart';

import 'payment_gateway_stub.dart'
    if (dart.library.io) 'payment_gateway_mobile.dart'
    if (dart.library.js_interop) 'payment_gateway_web.dart' as gateway;

typedef PaymentGatewayHandler = Future<PaymentResult> Function({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String userEmail,
  String? userPhone,
  String? userName,
  String? description,
});

class PaymentGatewayService {
  /// Test-only or custom gateway handler override.
  /// When non-null, [openCheckout] delegates to this handler instead of the native platform SDK.
  static PaymentGatewayHandler? mockHandler;

  static Future<PaymentResult> openCheckout({
    required String keyId,
    required String orderId,
    required int amountPaise,
    required String userEmail,
    String? userPhone,
    String? userName,
    String? description,
  }) {
    if (mockHandler != null) {
      return mockHandler!(
        keyId: keyId,
        orderId: orderId,
        amountPaise: amountPaise,
        userEmail: userEmail,
        userPhone: userPhone,
        userName: userName,
        description: description,
      );
    }
    return gateway.openPlatformCheckout(
      keyId: keyId,
      orderId: orderId,
      amountPaise: amountPaise,
      userEmail: userEmail,
      userPhone: userPhone,
      userName: userName,
      description: description,
    );
  }
}
