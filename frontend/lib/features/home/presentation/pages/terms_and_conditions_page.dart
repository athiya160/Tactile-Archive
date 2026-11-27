import 'package:flutter/material.dart';
import '../../../../core/widgets/tactile_footer.dart';

class TermsAndConditionsPageV2 extends StatelessWidget {
  const TermsAndConditionsPageV2({super.key});

  final List<Map<String, dynamic>> sections = const [
    {
      "title": "1. User Accounts",
      "content": [
        "Users must provide accurate registration information.",
        "Users are responsible for maintaining the security of their accounts and passwords.",
        "Accounts can be suspended for violating these terms.",
      ],
    },
    {
      "title": "2. Buying and Selling",
      "content": [
        "Sellers must provide accurate descriptions and images of books.",
        "Users must not list prohibited, illegal, or misleading content.",
        "The platform reserves the right to remove inappropriate listings.",
        "Buyers must pay for purchases promptly.",
      ],
    },
    {
      "title": "3. Renting and Borrowing",
      "content": [
        "Users must return rented or borrowed books within the agreed period.",
        "Late returns may result in penalties or account restrictions.",
        "Users are responsible for the condition of borrowed items.",
      ],
    },
    {
      "title": "4. Fees and Payments",
      "content": [
        "The platform may charge service fees on transactions.",
        "All fees are clearly stated before confirming a transaction.",
        "Payments are processed through secure third-party providers.",
      ],
    },
    {
      "title": "5. Dispute Resolution",
      "content": [
        "Users should attempt to resolve disputes directly.",
        "The platform may intervene if a resolution cannot be reached.",
        "Our decision in dispute cases is final.",
      ],
    },
  ];

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
                        'Terms and Conditions',
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
                              'Please read these terms and conditions carefully before using The Tactile Archive. By accessing or using our platform, you agree to be bound by these terms.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF061B0E),
                                height: 1.8,
                              ),
                            ),
                            const SizedBox(height: 40),

                            ...sections.map((section) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 32.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                      child: Text(
                                        section['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF061B0E),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...(section['content'] as List<String>).map((
                                      item,
                                    ) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(
                                                top: 8,
                                                right: 12,
                                              ),
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFF0D697),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                item,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xFF586159),
                                                  height: 1.6,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 16),
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
                                    'Questions about the Terms of Service?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF061B0E),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Please contact us at athiya160@gmail.com or call +91 99864 74220.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF586159),
                                      height: 1.6,
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
