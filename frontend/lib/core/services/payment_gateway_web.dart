import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'payment_result.dart';

@JS('payWithRazorpay')
external void _payWithRazorpay(JSString optionsJson, JSFunction callback);

Future<PaymentResult> openPlatformCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String userEmail,
  String? userPhone,
  String? userName,
  String? description,
}) async {
  final completer = Completer<PaymentResult>();

  final options = {
    'key': keyId,
    'amount': amountPaise,
    'currency': 'INR',
    'name': 'The Tactile Archive',
    'description': description ?? 'Book Marketplace Payment',
    'order_id': orderId,
    'prefill': {
      'contact': userPhone ?? '9999999999',
      'email': userEmail,
      if (userName != null) 'name': userName,
    },
    'theme': {
      'color': '#0D3B2E',
    },
  };

  void handleResult(JSString resultJson) {
    try {
      final map = jsonDecode(resultJson.toDart) as Map<String, dynamic>;
      final status = map['status'] as String?;
      if (status == 'success') {
        if (!completer.isCompleted) {
          completer.complete(PaymentResult.success(
            razorpayOrderId: map['orderId'] as String? ?? orderId,
            razorpayPaymentId: map['paymentId'] as String? ?? '',
            razorpaySignature: map['signature'] as String? ?? '',
          ));
        }
      } else if (status == 'cancelled') {
        if (!completer.isCompleted) {
          completer.complete(PaymentResult.cancelled());
        }
      } else {
        if (!completer.isCompleted) {
          completer.complete(PaymentResult.failure(map['message'] as String? ?? 'Payment failed'));
        }
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete(PaymentResult.failure('Failed to parse payment response: $e'));
      }
    }
  }

  try {
    _payWithRazorpay(jsonEncode(options).toJS, handleResult.toJS);
  } catch (e) {
    if (!completer.isCompleted) {
      completer.complete(PaymentResult.failure('Razorpay Web failed to initialize: $e'));
    }
  }

  return completer.future;
}
