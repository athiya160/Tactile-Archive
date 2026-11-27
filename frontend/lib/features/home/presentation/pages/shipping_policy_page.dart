import 'package:flutter/material.dart';
import '../../../../core/widgets/tactile_footer.dart';

class ShippingPolicyPage extends StatelessWidget {
  const ShippingPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 48.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900), // max-w-4xl
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      const SizedBox(height: 32),
                      const Text(
                        'Shipping Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF061B0E),
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Last updated: July 15, 2026',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Color(0xFF586159)),
                      ),
                      const SizedBox(height: 48),

                      // Main Content Card
                      Container(
                        padding: const EdgeInsets.all(48.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF061B0E).withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thank you for visiting and shopping at The Tactile Archive. The following are the terms and conditions that constitute our Shipping Policy.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF061B0E),
                                height: 1.8,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Section 1
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade100,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Domestic Shipping Processing Time',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF061B0E),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'All orders are processed within 2-3 business days. Orders are not shipped or delivered on weekends or holidays. If we are experiencing a high volume of orders, shipments may be delayed by a few days. Please allow additional days in transit for delivery.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF586159),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Section 2
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade100,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Shipping Rates & Delivery Estimates',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF061B0E),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Shipping charges for your order will be calculated and displayed at checkout. Delivery delays can occasionally occur.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF586159),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Contact Info Section
                            Container(
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contact Us',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF061B0E),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'If you have any questions about this Shipping Policy, please contact us:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF586159),
                                      height: 1.6,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Address: chame gowda area near khudadad masjid bh road bhadravthi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF586159),
                                      height: 1.6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Phone: 9986474220',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF586159),
                                      height: 1.6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Email: athiya160@gmail.com',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF586159),
                                      height: 1.6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const TactileFooter(),
          ],
        );

        return SingleChildScrollView(child: content);
      },
    );
  }
}
