import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SimulatedPaymentGateway extends StatefulWidget {
  final double amount;
  final String paymentMethod;
  final VoidCallback onComplete;

  const SimulatedPaymentGateway({
    super.key,
    required this.amount,
    required this.paymentMethod,
    required this.onComplete,
  });

  @override
  State<SimulatedPaymentGateway> createState() => _SimulatedPaymentGatewayState();
}

class _SimulatedPaymentGatewayState extends State<SimulatedPaymentGateway>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _step = 0; // 0: Initialize, 1: Process, 2: Success

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _startFlow();
  }

  void _startFlow() async {
    // Step 0: User input simulation
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _step = 1);
    
    // Step 1: Processing
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    setState(() => _step = 2);
    _controller.forward();
    
    // Step 2: Success & Dismiss
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 40,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.shieldHalved, color: DSColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Secure Checkout',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DSColors.textDark,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Dynamic Content based on step
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _buildContent(),
            ),
            
            const SizedBox(height: 32),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: DSColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DSColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount to Pay',
                    style: TextStyle(color: DSColors.textLight, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '₹${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: DSColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Payments are 100% secure and encrypted',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_step == 0) {
      // Initialize / Auth
      return Column(
        key: const ValueKey('step_0'),
        children: [
          Icon(
            widget.paymentMethod.toLowerCase().contains('upi') 
                ? Icons.qr_code_scanner 
                : Icons.credit_card,
            size: 64,
            color: DSColors.textLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: DSColors.primary),
          const SizedBox(height: 24),
          Text(
            'Initializing ${widget.paymentMethod.toUpperCase()}...',
            style: const TextStyle(color: DSColors.textDark, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please do not press back or close the app',
            style: TextStyle(color: DSColors.textLight, fontSize: 12),
          ),
        ],
      );
    } else if (_step == 1) {
      // Processing
      return Column(
        key: const ValueKey('step_1'),
        children: [
          const SizedBox(
            height: 64,
            width: 64,
            child: CircularProgressIndicator(
              color: DSColors.secondary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Processing Payment...',
            style: TextStyle(color: DSColors.textDark, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connecting to bank servers securely',
            style: TextStyle(color: DSColors.textLight, fontSize: 13),
          ),
        ],
      );
    } else {
      // Success
      return Column(
        key: const ValueKey('step_2'),
        children: [
          ScaleTransition(
            scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
            child: Container(
              height: 64,
              width: 64,
              decoration: const BoxDecoration(
                color: DSColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Payment Successful!',
            style: TextStyle(color: DSColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your order has been placed securely.',
            style: TextStyle(color: DSColors.textDark, fontSize: 14),
          ),
        ],
      );
    }
  }
}
