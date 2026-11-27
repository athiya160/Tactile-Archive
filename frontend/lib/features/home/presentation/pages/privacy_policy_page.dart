import 'package:flutter/material.dart';
import '../../../../core/widgets/tactile_footer.dart';

class PrivacyPolicyPageV2 extends StatelessWidget {
  const PrivacyPolicyPageV2({super.key});

  final List<Map<String, dynamic>> sections = const [
    {
      "title": "1. Information We Collect",
      "content": [
        "Personal Identity: Display name, email address, contact phone number, and persona classification (Reader, Student, or Provider).",
        "Security & Authentication: Passwords hashed with salted bcrypt; Google Sign-In verified via OAuth 2.0 cryptographic tokens.",
        "Profile & Academic Data: Reading goals, semester course schedules, wishlists, and Living Bookshelf catalog items.",
        "Transaction Records: Order history, transaction arrangement types (Buy, Rent, Borrow), payment status, and delivery addresses.",
      ],
    },
    {
      "title": "2. Camera & Photo Permissions (Smart Shelf Scanner & Listings)",
      "content": [
        "Smart Camera Shelf Scanner: The application requests CAMERA permission exclusively to scan ISBN barcodes and recognize books on physical shelves in real-time.",
        "Zero Remote Video Streaming: Optical barcode detection runs locally in volatile device memory; live camera feeds are never recorded, streamed, or stored on remote servers.",
        "Book Condition Documentation: Camera and photo library access is optionally used when providers photograph physical book covers or document wear for condition transparency.",
      ],
    },
    {
      "title": "3. Location Data & Community Exchange Map",
      "content": [
        "Peer-to-Peer Meetup Map: Location permissions (ACCESS_COARSE_LOCATION and ACCESS_FINE_LOCATION) are requested strictly while actively viewing the Community Exchange Map to display nearby public book meetup points and calculate distance for peer handoffs.",
        "No Background Tracking: We never track or monitor your device location in the background.",
        "No Location Brokerage: Coordinates are never sold, rented, or shared with third-party advertisers or data brokers.",
      ],
    },
    {
      "title": "4. Payment Processing & Financial Security (Razorpay & COD)",
      "content": [
        "PCI-DSS Compliant Gateway: Digital payments for book purchases, rental fees, and refundable security deposits are securely processed through Razorpay Payment Gateway.",
        "No Raw Card Storage: The Tactile Archive servers NEVER receive, process, or store sensitive credit/debit card numbers, CVVs, or UPI PINs.",
        "Statutory Payment Records: We retain only transaction IDs, payment status (paid, refund_pending, cod_pending), amount in paise, and payment method type for order fulfillment and taxation audits.",
        "Cash on Delivery: Cash on Delivery (COD) is supported for eligible orders with zero digital payment data collected.",
      ],
    },
    {
      "title": "5. Student & Reader Academic Privacy",
      "content": [
        "Academic Coursework: Course schedules, semester syllabi, and study goals entered in the Student Dashboard are private to your account and never shared publicly.",
        "Ambient Reading Companion: Atmospheric soundscapes (Library, Fireplace, Rain, Cafe) are stored locally in the application package and require zero microphone or audio-recording permissions.",
      ],
    },
    {
      "title": "6. User Data Retention, Erasure & Account Deletion (Google Play Compliance)",
      "content": [
        "In accordance with Google Play Store policies and international privacy regulations, users have full control over their account data and the right to permanent data erasure.",
        "In-App Self-Service Deletion: You can permanently delete your account directly inside the app via Profile -> Account Settings -> Danger Zone -> Delete Account.",
        "Immediate Data Erasure: Your name, email, contact phone number, saved delivery addresses, profile photo, reading history, student schedules, reading goals, favorites, and cart items are immediately and permanently erased.",
        "Delisting Provider Books: All active book listings belonging to your account are immediately delisted from the marketplace and archived.",
        "Active Fulfillment Safeguard: To protect community trust, accounts with active unreturned book rentals, active peer borrowings, or in-transit delivery orders cannot be deleted until all pending handoffs or returns are resolved.",
        "Statutory Tax & Audit Retention: In compliance with statutory commercial taxation and accounting laws, past completed transaction invoices and payment records are retained in a strictly anonymized form with all recipient personal identifying information permanently scrubbed ([Deleted User], [Redacted - Account Deleted]).",
      ],
    },
    {
      "title": "7. External Web Account Deletion Request Portal",
      "content": [
        "If you do not have access to the mobile application, you can submit an account deletion request through our web portal at https://the-tactile-archive-production.up.railway.app/delete-account or by contacting support@tactilearchive.org.",
        "Web-submitted account deletion requests are verified and processed within 30 days of receipt in accordance with statutory compliance timelines.",
      ],
    },
    {
      "title": "8. Contact & Data Protection Inquiries",
      "content": [
        "For questions regarding this Privacy Policy, your personal data, or data deletion requests, contact our Compliance Team at support@tactilearchive.org.",
        "The Tactile Archive / LibriFlow Data Protection Officer: support@tactilearchive.org | +91 99864 74220",
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
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
                          'Privacy Policy',
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
                          'Last updated: November 19, 2026',
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
                                'The Tactile Archive ("we", "our", "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our website and use our platform.',
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
                                      'Contact Us About Privacy',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF061B0E),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'If you have questions or comments about this Privacy Policy, please contact us at athiya160@gmail.com or call +91 99864 74220.',
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
          ),
        );
      },
    );
  }
}
