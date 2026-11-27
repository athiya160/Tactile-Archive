class PaymentResult {
  final bool isSuccess;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  final String? errorMessage;
  final bool isCancelled;

  const PaymentResult._({
    required this.isSuccess,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
    this.errorMessage,
    this.isCancelled = false,
  });

  factory PaymentResult.success({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) {
    return PaymentResult._(
      isSuccess: true,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    );
  }

  factory PaymentResult.cancelled() {
    return const PaymentResult._(
      isSuccess: false,
      isCancelled: true,
      errorMessage: 'Payment cancelled by user.',
    );
  }

  factory PaymentResult.failure(String message) {
    return PaymentResult._(
      isSuccess: false,
      isCancelled: false,
      errorMessage: message,
    );
  }
}
