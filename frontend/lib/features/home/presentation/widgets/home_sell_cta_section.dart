import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeSellCtaSection extends StatelessWidget {
  const HomeSellCtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFDFBF7),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E7), // Warm soft cream card
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFE0B2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sell Your Books',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D3B2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Earn from the books you no longer need.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF718096),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/sell'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D3B2E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                      icon: const FaIcon(FontAwesomeIcons.tag, size: 12),
                      label: Text(
                        'Start Selling →',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              const Icon(
                Icons.menu_book_rounded,
                size: 64,
                color: Color(0xFFC85A32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
