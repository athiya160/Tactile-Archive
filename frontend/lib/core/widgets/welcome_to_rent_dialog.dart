import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../features/home/domain/entities/book.dart';

/// Attractive, modern modal dialog prompting unauthenticated visitors to log in
/// when attempting to Rent, Borrow, or Purchase a book from the catalog.
class WelcomeToRentDialog extends StatelessWidget {
  final Book book;
  final String action; // 'rent', 'borrow', 'buy', 'cart'
  final int rentalDays;
  final VoidCallback? onProceedAfterAuth;

  const WelcomeToRentDialog({
    super.key,
    required this.book,
    this.action = 'rent',
    this.rentalDays = 14,
    this.onProceedAfterAuth,
  });

  static Future<void> show(
    BuildContext context, {
    required Book book,
    String action = 'rent',
    int rentalDays = 14,
    VoidCallback? onProceedAfterAuth,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => WelcomeToRentDialog(
        book: book,
        action: action,
        rentalDays: rentalDays,
        onProceedAfterAuth: onProceedAfterAuth,
      ),
    );
  }

  String get _actionTitle {
    switch (action.toLowerCase()) {
      case 'borrow':
        return 'Borrow';
      case 'buy':
        return 'Purchase';
      case 'cart':
        return 'Reserve';
      case 'rent':
      default:
        return 'Rent';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFA),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF0D3B2E).withValues(alpha: 0.12), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Emerald Accent Bar
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D3B2E), Color(0xFF1B5E20), Color(0xFFD4AF37)],
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(isMobile ? 20 : 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Row: Badge & Close Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFC8E6C9)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, color: Color(0xFF1B5E20), size: 12),
                                const SizedBox(width: 5),
                                Text(
                                  'THE TACTILE ARCHIVE',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: 'Close Dialog',
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                            ),
                          ),
                        ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Literary Welcome Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D3B2E), Color(0xFF165B47)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D3B2E).withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.bookBookmark,
                            color: Color(0xFFD4AF37),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Heading
                      Text(
                        'Welcome, Reader!',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: isMobile ? 24 : 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D3B2E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Please log in or create an account to $_actionTitle this volume through verified community hubs.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Book Snapshot Card Preview
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F5EE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5DFC9), width: 1.1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Book Cover
                            Container(
                              width: 54,
                              height: 78,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 6,
                                    offset: const Offset(2, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: book.coverUrl.isNotEmpty
                                    ? Image.network(
                                        book.coverUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _buildFallbackCover(),
                                      )
                                    : _buildFallbackCover(),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Book Title, Author & Terms
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    book.title,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0D3B2E),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'by ${book.author}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F4F0),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      action == 'borrow'
                                          ? '🤝 Free Swap • $rentalDays Days'
                                          : action == 'buy'
                                              ? '🛍️ Buy & Keep • ₹${book.price > 0 ? book.price.toStringAsFixed(0) : "350"}'
                                              : '⚡ Rent for $rentalDays Days • Smart Locker Ready',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0D3B2E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Trust Pillars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTrustPillar(Icons.security, 'Zero Deposit'),
                          _buildTrustPillar(Icons.lock_clock, '24/7 Lockers'),
                          _buildTrustPillar(Icons.verified, 'Safe Escrow'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Primary Action: Log In Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/login');
                          },
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: Text(
                            'Log In to Continue $_actionTitle',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D3B2E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary Action: Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/register');
                          },
                          icon: const Icon(Icons.person_add_outlined, size: 16),
                          label: Text(
                            'New Reader? Create Free Account',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0D3B2E),
                            side: const BorderSide(color: Color(0xFFCBD5E0), width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Dismiss Text Button
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Continue Browsing as Guest',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF718096),
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }

  Widget _buildTrustPillar(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF0D3B2E)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A5568),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      color: const Color(0xFF0D3B2E),
      child: const Center(
        child: Icon(Icons.book, color: Color(0xFFD4AF37), size: 24),
      ),
    );
  }
}
