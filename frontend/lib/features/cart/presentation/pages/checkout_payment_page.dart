import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

class CheckoutPaymentPage extends StatefulWidget {
  const CheckoutPaymentPage({super.key});

  @override
  State<CheckoutPaymentPage> createState() => _CheckoutPaymentPageState();
}

class _CheckoutPaymentPageState extends State<CheckoutPaymentPage> {
  String _selectedPaymentMethod = 'upi';
  String? _paymentFailureError;

  Future<void> _processPayment() async {
    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded) return;
    
    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: DSColors.primary),
      ),
    );

    try {
      // 1. Create payment session on the backend
      final orderRes = await ApiService.createPaymentOrder(
        _selectedPaymentMethod,
        'User Default Address', // Should be dynamic, hardcoded for now
      );
      
      if (mounted) Navigator.pop(context); // Close spinner

      if (orderRes['is_cod'] == true || _selectedPaymentMethod == 'cod') {
        if (mounted) {
          context.read<CartBloc>().add(CartCheckoutPressed());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully via Cash on Delivery!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/order-history');
        }
        return;
      }
      
      if (orderRes.isEmpty || orderRes['razorpay_order_id'] == null) {
        throw Exception('Failed to generate secure checkout session');
      }
      
      final String orderId = orderRes['razorpay_order_id'];
      final int amountPaise = orderRes['amount'];
      final String keyId = orderRes['key_id'];
      
      // 2. Open real Razorpay payment gateway SDK
      final paymentResult = await _startRazorpaySdkPayment(
        keyId,
        orderId,
        amountPaise,
      );
      
      if (paymentResult == null) {
        setState(() {
          _paymentFailureError = 'Payment cancelled by user.';
        });
        return;
      }
      
      // Show verifying spinner
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(
            child: CircularProgressIndicator(color: DSColors.primary),
          ),
        );
      }
      
      // 3. Verify Payment Signature
      final verifySuccess = await ApiService.verifyPayment(
        paymentResult['razorpay_order_id']!,
        paymentResult['razorpay_payment_id']!,
        paymentResult['razorpay_signature']!,
      );
      
      if (mounted) Navigator.pop(context); // Close spinner
      
      if (verifySuccess) {
        if (mounted) {
          context.read<CartBloc>().add(CartCheckoutPressed());
          context.go('/order-history');
        }
      } else {
        throw Exception('Cryptographic verification signature mismatch.');
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      setState(() {
        _paymentFailureError = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<Map<String, String>?> _startRazorpaySdkPayment(
    String keyId,
    String orderId,
    int amountPaise,
  ) {
    final completer = Completer<Map<String, String>?>();
    final razorpay = Razorpay();
    
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      razorpay.clear();
      completer.complete({
        'order_id': response.orderId ?? orderId,
        'payment_id': response.paymentId ?? '',
        'signature': response.signature ?? '',
      });
    });
    
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      razorpay.clear();
      completer.complete(null);
    });
    
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      razorpay.clear();
      completer.complete(null);
    });
    
    var options = {
      'key': keyId,
      'amount': amountPaise,
      'name': 'The Tactile Archive',
      'order_id': orderId,
      'description': 'Cart Checkout',
      'timeout': 120, // in seconds
    };
    
    try {
      razorpay.open(options);
    } catch (e) {
      completer.completeError(e);
    }
    
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return IvoryScaffold(
      title: 'Checkout (2/2)',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DSSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: DSSpacing.lg),
                if (_paymentFailureError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(DSSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: DSSpacing.sm),
                        Expanded(
                          child: Text(
                            _paymentFailureError!,
                            style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DSSpacing.md),
                ],
                _PaymentOption(
                  id: 'upi',
                  title: 'UPI',
                  subtitle: 'Google Pay, PhonePe, Paytm',
                  icon: Icons.qr_code_scanner,
                  selected: _selectedPaymentMethod == 'upi',
                  onSelect: (id) => setState(() => _selectedPaymentMethod = id),
                ),
                const SizedBox(height: DSSpacing.md),
                _PaymentOption(
                  id: 'card',
                  title: 'Credit / Debit Card',
                  subtitle: 'Visa, MasterCard, RuPay',
                  icon: Icons.credit_card,
                  selected: _selectedPaymentMethod == 'card',
                  onSelect: (id) => setState(() => _selectedPaymentMethod = id),
                ),
                const SizedBox(height: DSSpacing.md),
                _PaymentOption(
                  id: 'cod',
                  title: 'Cash on Delivery',
                  subtitle: 'Pay when your order arrives',
                  icon: Icons.local_shipping_outlined,
                  selected: _selectedPaymentMethod == 'cod',
                  onSelect: (id) => setState(() => _selectedPaymentMethod = id),
                ),
                const SizedBox(height: DSSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: DSButton(
                    text: 'PLACE ORDER',
                    onPressed: () {
                      _processPayment();
                    },
                  ),
                ),
                const SizedBox(height: DSSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Function(String) onSelect;
  const _PaymentOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(id),
      child: Container(
        padding: const EdgeInsets.all(DSSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? DSColors.primary.withValues(alpha: 0.05)
              : DSColors.surface,
          borderRadius: BorderRadius.circular(DSRadius.lg),
          border: Border.all(
            color: selected
                ? DSColors.primary
                : DSColors.borderLight.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? DSColors.primary : DSColors.textLight),
            const SizedBox(width: DSSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? DSColors.primary : DSColors.textDark,
                    ),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: DSColors.primary),
          ],
        ),
      ),
    );
  }
}
