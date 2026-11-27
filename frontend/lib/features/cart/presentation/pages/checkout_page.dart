import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/book_cover_image.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/payment_gateway_service.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _currentStep = 0;
  String _selectedPaymentMethod = 'upi';
  bool _isProcessing = false;

  final String _defaultRecipient = 'Athiya Tabassum';
  final String _defaultPhone = '+91 99864 74220';
  final String _defaultAddress = 'Flat 402, Green Valley Apartments, 12th Main Road, Indiranagar, Bangalore, Karnataka - 560038';

  @override
  void initState() {
    super.initState();
    final currentState = context.read<CartBloc>().state;
    if (currentState is CartInitial) {
      context.read<CartBloc>().add(CartStarted());
    }
  }

  Future<void> _handlePlaceOrder(dynamic cart) async {
    setState(() => _isProcessing = true);

    final shippingAddress = (cart.deliveryAddress != null && cart.deliveryAddress.toString().trim().isNotEmpty)
        ? cart.deliveryAddress.toString()
        : _defaultAddress;

    final paymentMethodCode = _selectedPaymentMethod == 'pickup' ? 'cod' : _selectedPaymentMethod;

    try {
      final orderRes = await ApiService.createPaymentOrder(
        paymentMethodCode,
        shippingAddress,
        mode: 'cart',
      );

      if (!mounted) return;

      final isCod = orderRes['is_cod'] == true || paymentMethodCode == 'cod';
      final orderId = orderRes['order_id'] ?? orderRes['razorpay_order_id'] ?? 'ORD-2026';

      if (isCod) {
        context.read<CartBloc>().add(CartCheckoutPressed());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Order #$orderId placed successfully via Cash on Delivery!'),
            backgroundColor: const Color(0xFF166534),
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/order-history');
        return;
      }

      // Online payment via Razorpay
      final rzpOrderId = orderRes['razorpay_order_id'] as String?;
      final keyId = orderRes['key_id'] as String?;
      final amountPaise = (orderRes['amount'] as num?)?.toInt() ?? ((cart.total as num) * 100).toInt();

      if (rzpOrderId == null || keyId == null || keyId.isEmpty) {
        throw Exception("Invalid payment configuration returned by server");
      }

      final result = await PaymentGatewayService.openCheckout(
        keyId: keyId,
        orderId: rzpOrderId,
        amountPaise: amountPaise,
        userEmail: ApiService.token != null ? 'customer@tactilearchive.com' : 'guest@tactilearchive.com',
        userPhone: _defaultPhone,
        userName: _defaultRecipient,
        description: 'LibriFlow Cart Checkout',
      );

      if (!mounted) return;

      if (result.isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled. Your cart has been preserved.'),
            backgroundColor: Color(0xFFC05621),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      if (!result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${result.errorMessage ?? "Transaction could not be completed."}'),
            backgroundColor: const Color(0xFF991B1B),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Verify payment signature on backend
      final verificationRes = await ApiService.verifyPaymentDetailed(
        result.razorpayOrderId ?? rzpOrderId,
        result.razorpayPaymentId ?? '',
        result.razorpaySignature ?? '',
      );

      if (!mounted) return;

      if (verificationRes['reconciliation'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Stock Unavailable — Refund Pending'),
            content: Text(
              verificationRes['message']?.toString() ??
                  'Payment was captured, but an item in your cart is no longer in stock. '
                  'A full refund has been initiated to your original payment method.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/order-history');
                },
                child: const Text('View Orders'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/browse');
                },
                child: const Text('Browse Books'),
              ),
            ],
          ),
        );
        return;
      }

      if (verificationRes['success'] == true ||
          verificationRes['message'] == 'Payment verified successfully') {
        final confirmedOrderId = verificationRes['order_id'] ?? orderId;
        context.read<CartBloc>().add(CartCheckoutPressed());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Payment verified! Order #$confirmedOrderId confirmed.'),
            backgroundColor: const Color(0xFF166534),
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/order-history');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verificationRes['message']?.toString() ??
                  'Payment signature verification failed. Please contact support.',
            ),
            backgroundColor: const Color(0xFF991B1B),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout encountered an error: $e'),
          backgroundColor: const Color(0xFF991B1B),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IvoryScaffold(
      title: 'Secure Checkout',
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.pop(),
      ),
      body: BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is CartInitial || state is CartLoading) {
            return const Center(
              child: CircularProgressIndicator(color: DSColors.primary),
            );
          }

          if (state is CartLoaded) {
            final cart = state.cart;
            if (cart.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: DSColors.textLight.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: DSColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add books to your cart to proceed with checkout.',
                      style: TextStyle(
                        fontSize: 14,
                        color: DSColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/browse'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DSColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DSRadius.lg),
                        ),
                      ),
                      child: const Text('Browse Catalog'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _buildStepIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(DSSpacing.xl),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_currentStep == 0) _buildAddressSection(cart),
                            if (_currentStep == 1) _buildPaymentSection(),
                            if (_currentStep == 2) _buildReviewSection(cart),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildBottomBar(cart),
              ],
            );
          }

          return Center(
            child: ElevatedButton(
              onPressed: () => context.read<CartBloc>().add(CartStarted()),
              child: const Text('Retry'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: DSSpacing.lg),
      color: DSColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepDot(index: 0, current: _currentStep, label: 'Address'),
          _StepLine(active: _currentStep > 0),
          _StepDot(index: 1, current: _currentStep, label: 'Payment'),
          _StepLine(active: _currentStep > 1),
          _StepDot(index: 2, current: _currentStep, label: 'Review'),
        ],
      ),
    );
  }

  Widget _buildAddressSection(dynamic cart) {
    final recipient = (cart.recipientName != null && cart.recipientName.toString().trim().isNotEmpty)
        ? cart.recipientName.toString()
        : _defaultRecipient;
    final address = (cart.deliveryAddress != null && cart.deliveryAddress.toString().trim().isNotEmpty)
        ? cart.deliveryAddress.toString()
        : _defaultAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shipping Address',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: DSSpacing.lg),
        Container(
          padding: const EdgeInsets.all(DSSpacing.xl),
          decoration: BoxDecoration(
            color: DSColors.surface,
            borderRadius: BorderRadius.circular(DSRadius.xl),
            border: Border.all(
              color: DSColors.borderLight.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: DSColors.primary,
                  ),
                  const SizedBox(width: DSSpacing.sm),
                  Expanded(
                    child: Text(
                      recipient,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Text(
                      'PRIMARY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: DSColors.textLight),
                  const SizedBox(width: 6),
                  Text(
                    _defaultPhone,
                    style: const TextStyle(fontSize: 13, color: DSColors.textLight),
                  ),
                ],
              ),
              const SizedBox(height: DSSpacing.md),
              Text(
                address,
                style: const TextStyle(color: DSColors.textDark, height: 1.4),
              ),
              const SizedBox(height: DSSpacing.xl),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push('/delivery-address'),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Address'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DSColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DSRadius.lg),
                      ),
                    ),
                  ),
                  const SizedBox(width: DSSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/delivery-address'),
                    icon: const Icon(Icons.change_circle_outlined, size: 16),
                    label: const Text('Change'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DSColors.textDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DSRadius.lg),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: DSSpacing.lg),
        _PaymentOption(
          id: 'upi',
          title: 'UPI (Instant)',
          subtitle: 'Google Pay, PhonePe, Paytm, BHIM QR',
          icon: Icons.qr_code_scanner,
          selected: _selectedPaymentMethod == 'upi',
          onSelect: (id) => setState(() => _selectedPaymentMethod = id),
        ),
        const SizedBox(height: DSSpacing.md),
        _PaymentOption(
          id: 'card',
          title: 'Credit / Debit Card',
          subtitle: 'Visa, MasterCard, RuPay (Razorpay)',
          icon: Icons.credit_card,
          selected: _selectedPaymentMethod == 'card',
          onSelect: (id) => setState(() => _selectedPaymentMethod = id),
        ),
        const SizedBox(height: DSSpacing.md),
        _PaymentOption(
          id: 'pickup',
          title: 'Cash on Delivery (Pay on Collection)',
          subtitle: 'Pay cash or UPI upon delivery or hub collection',
          icon: Icons.local_shipping_outlined,
          selected: _selectedPaymentMethod == 'pickup',
          onSelect: (id) => setState(() => _selectedPaymentMethod = id),
        ),
        const SizedBox(height: DSSpacing.md),
        _PaymentOption(
          id: 'points',
          title: 'Community Points / Credits',
          subtitle: 'Use your accumulated platform reading credits',
          icon: Icons.stars_outlined,
          selected: _selectedPaymentMethod == 'points',
          onSelect: (id) => setState(() => _selectedPaymentMethod = id),
        ),
      ],
    );
  }

  Widget _buildReviewSection(dynamic cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Order',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: DSSpacing.lg),
        ...cart.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: DSSpacing.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DSRadius.sm),
                  child: BookCoverImage(
                    url: item.coverUrl,
                    width: 44,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: DSSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item.author,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        'Qty: ${item.quantity}',
                        style: const TextStyle(fontSize: 12, color: DSColors.textLight),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: DSSpacing.xxl),
        _SummaryLine('Subtotal', '₹${cart.subtotal.toStringAsFixed(2)}'),
        _SummaryLine('Archive Fee', '₹${cart.archiveFee.toStringAsFixed(2)}'),
        _SummaryLine(
          'Shipping',
          cart.shippingFee == 0
              ? 'FREE'
              : '₹${cart.shippingFee.toStringAsFixed(2)}',
        ),
        const SizedBox(height: DSSpacing.md),
        _SummaryLine(
          'Total Payable',
          '₹${cart.total.toStringAsFixed(2)}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildBottomBar(dynamic cart) {
    final isLastStep = _currentStep == 2;

    return Container(
      padding: const EdgeInsets.all(DSSpacing.xl),
      decoration: BoxDecoration(
        color: DSColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: DSSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DSRadius.lg),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: DSSpacing.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () {
                        if (isLastStep) {
                          _handlePlaceOrder(cart);
                        } else {
                          setState(() => _currentStep++);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DSColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DSRadius.lg),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isLastStep
                            ? (_selectedPaymentMethod == 'pickup'
                                ? 'PLACE COD ORDER (₹${cart.total.toStringAsFixed(2)})'
                                : 'PAY & PLACE ORDER (₹${cart.total.toStringAsFixed(2)})')
                            : 'CONTINUE',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final int current;
  final String label;
  const _StepDot({
    required this.index,
    required this.current,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index <= current;
    final isDone = index < current;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? DSColors.primary : DSColors.borderLight,
            shape: BoxShape.circle,
          ),
          child: isDone
              ? const Icon(Icons.check, color: DSColors.textInverse, size: 14)
              : Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive
                          ? DSColors.textInverse
                          : DSColors.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? DSColors.primary : DSColors.textLight,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 14),
      color: active ? DSColors.primary : DSColors.borderLight,
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

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  const _SummaryLine(this.label, this.value, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                : TextStyle(color: DSColors.textLight),
          ),
          Text(
            value,
            style: isTotal
                ? const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: DSColors.primary,
                  )
                : const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
