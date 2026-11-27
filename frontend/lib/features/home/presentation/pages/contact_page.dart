import '../../../../core/design_system/tokens/ds_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/widgets/tactile_footer.dart';
import '../../../../core/services/api_service.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitted = false;
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await ApiService.post(
          '/support/contact',
          data: {
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'subject': _subjectController.text.trim(),
            'message': _messageController.text.trim(),
            'phone': _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : '9986474220',
          },
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSubmitted = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message sent successfully! Our team has received your inquiry.'),
              backgroundColor: Color(0xFF0D3B2E),
            ),
          );
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) {
              setState(() {
                _isSubmitted = false;
                _nameController.clear();
                _emailController.clear();
                _phoneController.clear();
                _subjectController.clear();
                _messageController.clear();
              });
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to dispatch message: ${e.toString()}'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DSColors.warmIvory,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // 1. TOP HEADER BANNER
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'CONTACT US',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: DSColors.deepForestGreen,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "We'd Love to Hear From You!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: DSColors.deepForestGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Have a question, feedback, or need help? We're here for you.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF718096),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // 2. MAIN SPLIT CARD: SEND US A MESSAGE vs OTHER WAYS TO REACH US
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 760;

                        final formCard = Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEDF2F7)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isSubmitted
                              ? Container(
                                  height: 320,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE6F4EE),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check_circle_outline, size: 32, color: Color(0xFF0D3B2E)),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Message Sent!',
                                        style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Thank you for reaching out. We will get back to you shortly.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF718096)),
                                      ),
                                    ],
                                  ),
                                )
                              : Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Send Us a Message',
                                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
                                      ),
                                      const SizedBox(height: 20),

                                      // Your Name
                                      Text('Your Name', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _nameController,
                                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                        decoration: InputDecoration(
                                          hintText: 'Enter your name',
                                          hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Email Address
                                      Text('Email Address', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _emailController,
                                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                        decoration: InputDecoration(
                                          hintText: 'Enter your email',
                                          hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Phone Number
                                      Text('Phone Number (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          hintText: 'e.g. 9986474220',
                                          hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Subject
                                      Text('Subject', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _subjectController,
                                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                        decoration: InputDecoration(
                                          hintText: 'How can we help you?',
                                          hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Message
                                      Text('Message', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _messageController,
                                        maxLines: 4,
                                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                        decoration: InputDecoration(
                                          hintText: 'Write your message...',
                                          hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Send Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 46,
                                        child: ElevatedButton.icon(
                                          onPressed: _isLoading ? null : _handleSubmit,
                                          icon: _isLoading
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Icon(Icons.send, size: 16),
                                          label: Text(_isLoading ? 'Sending...' : 'Send Message', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: DSColors.deepForestGreen,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        );

                        final reachUsCard = Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEDF2F7)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Other Ways to Reach Us',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
                              ),
                              const SizedBox(height: 24),

                              _buildContactMethodItem(
                                icon: Icons.email_outlined,
                                title: 'Email Us',
                                detail: 'athiya160@gmail.com',
                              ),
                              const SizedBox(height: 20),

                              _buildContactMethodItem(
                                icon: Icons.phone_outlined,
                                title: 'Call Us',
                                detail: '+91 99864 74220\nMon - Sat, 9:00 AM - 6:00 PM',
                              ),
                              const SizedBox(height: 20),

                              _buildContactMethodItem(
                                icon: Icons.location_on_outlined,
                                title: 'Visit Our Office',
                                detail: 'Chame Gowda, Bhadravathi,\nShimoga, Karnataka, India',
                              ),
                              const SizedBox(height: 32),

                              Text(
                                'Follow Us',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildSocialIconButton(FontAwesomeIcons.facebookF),
                                  const SizedBox(width: 10),
                                  _buildSocialIconButton(FontAwesomeIcons.instagram),
                                  const SizedBox(width: 10),
                                  _buildSocialIconButton(FontAwesomeIcons.xTwitter),
                                  const SizedBox(width: 10),
                                  _buildSocialIconButton(FontAwesomeIcons.linkedinIn),
                                ],
                              ),
                            ],
                          ),
                        );

                        if (isDesktop) {
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 6, child: formCard),
                                const SizedBox(width: 24),
                                Expanded(flex: 5, child: reachUsCard),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            formCard,
                            const SizedBox(height: 24),
                            reachUsCard,
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // 3. FREQUENTLY ASKED QUESTIONS BOTTOM BANNER
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F7F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2EFE9)),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth >= 600;

                          final textSection = Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE6F4EE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.help_outline, color: Color(0xFF0D3B2E), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Frequently Asked Questions',
                                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Find quick answers to common questions in our Help Center.',
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4A5568)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );

                          final actionBtn = OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Navigating to Help Center...')),
                              );
                            },
                            icon: Text('Visit Help Center', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen)),
                            label: const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF0D3B2E)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0D3B2E)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );

                          if (isDesktop) {
                            return Row(
                              children: [
                                Expanded(child: textSection),
                                const SizedBox(width: 16),
                                actionBtn,
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              textSection,
                              const SizedBox(height: 14),
                              SizedBox(width: double.infinity, child: actionBtn),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
            const TactileFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethodItem({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFE6F4EE),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: DSColors.deepForestGreen),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIconButton(dynamic icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: FaIcon(icon, size: 14, color: DSColors.deepForestGreen),
        ),
      ),
    );
  }
}
