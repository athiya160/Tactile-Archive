import 'dart:async';
import 'dart:io' show Platform;
import 'package:razorpay_flutter/razorpay_flutter.dart';
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
  if (!Platform.isAndroid && !Platform.isIOS) {
    return PaymentResult.failure(
      'Razorpay mobile SDK is only supported on Android and iOS devices. '
      'For desktop testing, please use Cash on Delivery (COD) or run inside Flutter Web / Mobile Emulator.',
    );
  }

  final completer = Completer<PaymentResult>();
  final razorpay = Razorpay();

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
    razorpay.clear();
    if (!completer.isCompleted) {
      completer.complete(PaymentResult.success(
        razorpayOrderId: response.orderId ?? orderId,
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      ));
    }
  });

  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    razorpay.clear();
    if (!completer.isCompleted) {
      if (response.code == Razorpay.PAYMENT_CANCELLED) {
        completer.complete(PaymentResult.cancelled());
      } else {
        completer.complete(PaymentResult.failure(response.message ?? 'Payment failed'));
      }
    }
  });

  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
    razorpay.clear();
    if (!completer.isCompleted) {
      completer.complete(PaymentResult.failure(
        'Selected external wallet is not supported. Please select UPI or Card.',
      ));
    }
  });

  final options = {
    'key': keyId,
    'amount': amountPaise,
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
    'send_sms_hash': false,
  };

  try {
    razorpay.open(options);
  } catch (e) {
    razorpay.clear();
    return PaymentResult.failure('Failed to initialize Razorpay SDK: $e');
  }

  return completer.future;
}
